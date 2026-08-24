# :stopdoc:
################################################################
################################################################
##  ________  ___  ___  ___       ___  __              ________  ________  _______   ________  ________  _________  ___  ________  ________      
## |\   __  \|\  \|\  \|\  \     |\  \|\  \           |\   __  \|\   __  \|\  ___ \ |\   __  \|\   __  \|\___   ___\\  \|\   __  \|\   ___  \    
## \ \  \|\ /\ \  \\\  \ \  \    \ \  \/  /|_         \ \  \|\  \ \  \|\  \ \  \__ /|\ \  \|\ \ \  \|\  \|___ \  \_\ \  \ \  \|\  \ \  \\ \  \   
##  \ \   __  \ \  \\\  \ \  \    \ \   ___  \         \ \  \\\  \ \   ____\ \  \_|/_\ \  _  __\ \  .__  \   \ \  \ \ \  \ \  \\\  \ \  \\ \  \  
##   \ \  \|\  \ \  \\\  \ \  \____\ \  \\ \  \         \ \  \\\  \ \  \___|\ \  \_|\ \ \  \\  \\ \  \ \  \   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ 
##    \ \_______\ \_______\ \_______\ \__\\ \__\         \ \_______\ \__\    \ \_______\ \__\\ _\\ \__\ \__\   \ \__\ \ \__\ \_______\ \__\\ \__\
##     \|_______|\|_______|\|_______|\|__| \|__|          \|_______|\|__|     \|_______|\|__|\|__|\|__|\|__|    \|__|  \|__|\|_______|\|__| \|__|
##                                                                                                                                            
## --
##  RPECK 24/01/2024 - Shopify Bulk Operation Management
##  Gives us the ability to tie an import to a bulk operation
##  Ref: https://shopify.dev/docs/api/admin-graphql/latest/objects/bulkoperation
################################################################
################################################################
# :stopdoc:

# frozen_string_literal: true

require "active_support/core_ext/string/indent"
require "tempfile"

module XEngine
  module Shopify
    # = Shopify Bulk Operation Model
    #
    # Tracks asynchronous GraphQL bulk data operations initiated against Shopify's cloud 
    # infrastructure. This model encapsulates bulk operation tracking, query generation, 
    # network dispatching, and streaming remote JSONL payload files to local temporary files.
    #
    # == Key Responsibilities
    # 1. *Query Construction:* Dynamically builds Shopify-compliant GraphQL bulk queries by 
    #    extracting representation fragments from target domain models and search filters.
    # 2. *Dual-Mode Request Dispatch:* Implements +#build_graphql_request+ to yield a 
    #    dispatch mutation (+bulkOperationRunQuery+) when un-synced, or delegate to standard 
    #    +HasGraphQLRepresentation+ polling queries once persisted with a +shopify_id+.
    # 3. *Execution Tracking:* Persists the returned Shopify Global ID (+shopify_id+) and status 
    #    atomically upon successful API acceptance.
    #
    # == Example Usage
    #   bulk_op = shop.bulk_operations.build(
    #     object_type: "XEngine::Shopify::Product",
    #     filter: "created_at:2026-01-01..2026-12-31"
    #   )
    #
    #   query, variables = bulk_op.build_graphql_request
    #   response = shop.graphql_client.query(query: query, variables: variables)
    #
    class BulkOperation < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Exposes local model attributes back to GraphQL nodes when fetching operation state.
      expose_graphql single: :node, mutation: :bulkOperationRunQuery do
        <<~GRAPHQL
          __typename
          ... on BulkOperation {
            shopify_id:        id
            status
            error_code:       errorCode
            created_at:       createdAt
            completed_at:     completedAt
            object_count:     objectCount
            root_object_count: rootObjectCount
            file_size:         fileSize
            url
            partial_data_url: partialDataUrl
        }
        GRAPHQL
      end

      # Alias plural 'filters' to the backing 'filter' schema column for API backwards compatibility
      alias_attribute :filters, :filter

      # Custom writer for +object_type+ to immediately resolve and construct the GraphQL query
      # if assigned or modified after initialization.
      #
      # === Parameters
      # * +value+ [+String+, +Class+] - The class name or class object representing the target model.
      #
      # === Returns
      # * [+String+, +Class+] The assigned value.
      #
      def object_type=(value)
        super
        resolve_and_set_query if object_type.present?
      end

      # Custom writer for +filter+ to re-compile the outbound query document on assignment.
      #
      # === Parameters
      # * +value+ [+String+, +nil+] - Search filter query string passed to Shopify GQL search.
      #
      # === Returns
      # * [+String+, +nil+] The assigned filter value.
      #
      def filter=(value)
        super
        resolve_and_set_query if object_type.present?
      end

      # ---
      # :section: Associations
      # ---

      # The parent store tenant owning the execution context for this bulk operation.
      belongs_to :shop,
                 class_name: "XEngine::Shopify::Shop",
                 foreign_key: :shop_id,
                 inverse_of: :bulk_operations

      # ---
      # :section: Validations
      # ---

      validates :shop, presence: true
      validates :object_type, presence: true

      # ---
      # :section: Lifecycle Hooks
      # ---

      after_initialize :resolve_and_set_query, if: -> { query.blank? && object_type.present? }

      # ---
      # :section: Instance Methods
      # ---

      # Dynamically determines the appropriate GraphQL request payload depending on local record state.
      #
      # When unsourced (+shopify_id+ is blank), constructs the +bulkOperationRunQuery+ 
      # mutation to initiate the bulk operation on Shopify.
      #
      # When sourced (+shopify_id+ is present), delegates to +HasGraphQLRepresentation#build_graphql_request+
      # to fetch current bulk operation status from Shopify.
      #
      # === Returns
      # * [+Array(String, Hash)+] A tuple containing the GraphQL string document and variable bindings hash.
      #
      # === Examples
      #   bulk_op.build_graphql_request
      #   # => ["mutation BulkOperationRunQuery($query: String!) { ... }", {:query=>"{ products { ... } }"}]
      #
      def build_graphql_request
        if shopify_id.blank?
          build_creation_mutation
        else
          super # Delegates to HasGraphQLRepresentation standard query generator
        end
      end

      # Helper indicating if the bulk operation execution has completed successfully on Shopify.
      #
      # === Returns
      # * [+Boolean+] +true+ if status is equal to +"completed"+ (case-insensitive), otherwise +false+.
      #
      def completed?
        status.to_s.downcase == "completed"
      end

      private

      # Generates the +bulkOperationRunQuery+ GraphQL mutation tuple for initializing a bulk operation on Shopify.
      #
      # === Returns
      # * [+Array(String, Hash)+] Mutation GQL document and variables hash containing the inner query payload.
      #
      def build_creation_mutation
        mutation = <<~GRAPHQL
          mutation BulkOperationRunQuery($query: String!) {
            bulkOperationRunQuery(query: $query) {
              bulkOperation {
                __typename
                shopify_id: id
                status
                created_at: createdAt
                error_code: errorCode
              }
              userErrors {
                field
                message
              }
            }
          }
        GRAPHQL

        [mutation, { query: query.to_s.strip }]
      end

      # Resolves the target model class and constructs the formatted Shopify bulk GraphQL query string.
      #
      # Inspects +object_type+ to obtain the target class's root GraphQL field name and selection set 
      # from +_graphql_query_block+. Wraps the inner fields in the +edges { node { ... } }+ structure 
      # required by Shopify's bulk API parser.
      #
      # === Returns
      # * [+String+] The compiled query string written directly to the +query+ attribute.
      #
      def resolve_and_set_query
        return if object_type.blank?

        target_klass = object_type.is_a?(Class) ? object_type : Object.const_get(object_type.to_s)

        root_field = if target_klass.respond_to?(:graphql_endpoint) && target_klass.graphql_endpoint(:multiple).present?
                       target_klass.graphql_endpoint(:multiple)
                     elsif target_klass.respond_to?(:graphql_root_field)
                       target_klass.graphql_root_field
                     else
                       target_klass.model_name.element.pluralize
                     end

        selection = target_klass.graphql_query.indent(8)
        
        # Explicitly read from self.filter to capture unsaved attribute changes
        raw_filter = read_attribute(:filter).presence || filter.presence
        active_filter = raw_filter || (target_klass.respond_to?(:graphql_default_filter) ? target_klass.graphql_default_filter : nil)

        # Safely construct the GraphQL query argument
        query_filter = active_filter.present? ? "(query: #{active_filter.strip.to_json})" : ""

        self.query = <<~GRAPHQL.strip
          {
            #{root_field}#{query_filter} {
              edges {
                node {
          #{selection}
                }
              }
            }
          }
        GRAPHQL
      end

      # Checks if the remote JSONL download URL has expired.
      #
      # Shopify bulk operation download URLs are ephemeral and expire strictly 7 days 
      # after completion. Evaluates the URL presence and tests timestamp age against 7 days ago.
      #
      # === Returns
      # * [+Boolean+] +true+ if URL is blank or completion timestamp is older than 7 days, otherwise +false+.
      #
      def url_expired?
        return true if url.blank?

        timestamp = completed_at || updated_at || created_at
        timestamp.blank? || timestamp < 7.days.ago
      end

    end
  end
end