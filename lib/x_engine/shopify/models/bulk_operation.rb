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

module XEngine
  module Shopify
    # = Shopify Bulk Operation Model
    #
    # Tracks asynchronous GraphQL bulk data operations initiated against Shopify's cloud 
    # infrastructure. This model encapsulates bulk operation tracking, query generation, 
    # and direct GraphQL mutation dispatching.
    #
    # == Key Responsibilities
    # 1. **Query Construction:** Dynamically builds Shopify-compliant GraphQL bulk queries by 
    #    extracting representation fragments from target domain models.
    # 2. **Network Dispatch:** Executes the +bulkOperationRunQuery+ mutation against the 
    #    owning shop's GraphQL endpoint.
    # 3. **Execution Tracking:** Persists the returned Shopify Global ID (+shopify_id+) and status 
    #    atomically upon successful API acceptance.
    #
    # == Example Usage
    #   bulk_op = shop.bulk_operations.build(object_type: XEngine::Shopify::Product)
    #   bulk_op.dispatch!
    #
    class BulkOperation < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Exposes local model attributes back to GraphQL nodes when fetching operation state.
      expose_graphql single: :node, multiple: :bulk_operations do
        <<~GRAPHQL
          ... on BulkOperation {
            __typename
            id
            status
            error_code: errorCode
            created_at: createdAt
            completed_at: completedAt
            object_count: objectCount
            root_object_count: rootObjectCount
            file_size: fileSize
            download_url: url
            query
          }
        GRAPHQL
      end

      # ---
      # :section: Attribute Accessors
      # ---

      # [Object, Class, Symbol, String] The target model class (e.g., +XEngine::Shopify::Product+) 
      # used to construct the root GraphQL selection fragment.
      attr_accessor :object_type

      # [String, NilClass] Optional search filter parameters passed directly to the root query line 
      # (e.g., <tt>"status:active AND updated_at:>=2026-01-01"</tt>).
      attr_accessor :filters

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

      # ---
      # :section: Lifecycle Hooks
      # ---

      before_validation :resolve_and_set_query, if: -> { query.blank? && object_type.present? }

      # ---
      # :section: Instance Methods
      # ---

      # Dispatches the generated bulk GraphQL query to Shopify's Admin API.
      #
      # Executes the +bulkOperationRunQuery+ mutation using the associated shop's GraphQL client.
      # On success, assigns the returned +shopify_id+ and +status+ to self and persists the record.
      #
      # @return [Boolean] +true+ if the operation was accepted by Shopify and saved locally, 
      #   +false+ if validation or API errors occurred.
      # @raise [ArgumentError] If +shop+ or +query+ is missing prior to execution.
      #
      # == Examples
      #   bulk_op = shop.bulk_operations.build(object_type: "XEngine::Shopify::Product")
      #   if bulk_op.dispatch!
      #     puts "Dispatched operation: #{bulk_op.shopify_id}"
      #   else
      #     puts "Failed: #{bulk_op.errors.full_messages.join(', ')}"
      #   end
      #
      def dispatch!
        raise ArgumentError, "Cannot dispatch without a valid shop" if shop.blank?
        raise ArgumentError, "Cannot dispatch without a generated query" if query.blank?

        mutation = <<~GRAPHQL
          mutation {
            bulkOperationRunQuery(
              query: """#{query.strip}"""
            ) {
              bulkOperation {
                id
                status
              }
              userErrors {
                field
                message
              }
            }
          }
        GRAPHQL

        response = shop.graphql_client.query(query: mutation)
        payload  = response.body.dig("data", "bulkOperationRunQuery")
        errors   = payload&.dig("userErrors") || []

        if errors.any?
          messages = errors.map { |e| "#{e['field']}: #{e['message']}" }.join(", ")
          self.errors.add(:base, "Shopify dispatch failed: #{messages}")
          return false
        end

        bulk_op_data = payload&.dig("bulkOperation")
        if bulk_op_data.blank?
          self.errors.add(:base, "Shopify returned no operation payload")
          return false
        end

        assign_attributes(
          shopify_id: bulk_op_data["id"],
          status:     bulk_op_data["status"]&.downcase || "created"
        )

        save!
      end

      private

      # Resolves the target model class and constructs the formatted Shopify bulk GraphQL query string.
      #
      # Inspects +object_type+ to obtain the target class's root GraphQL field name and selection set 
      # from +_graphql_query_block+. Wraps the inner fields in the +edges { node { ... } }+ structure 
      # required by Shopify's bulk API parser.
      #
      # @return [void]
      # @api private
      #
      def resolve_and_set_query
        target_klass = object_type.is_a?(Class) ? object_type : Object.const_get(object_type.to_s)
        
        root_field   = if target_klass.respond_to?(:graphql_endpoint) && target_klass.graphql_endpoint(:multiple).present?
                         target_klass.graphql_endpoint(:multiple)
                       elsif target_klass.respond_to?(:graphql_root_field)
                         target_klass.graphql_root_field
                       else
                         target_klass.model_name.element.pluralize
                       end

        selection     = target_klass.graphql_query.indent(8)
        active_filter = filters.presence || (target_klass.respond_to?(:graphql_default_filter) ? target_klass.graphql_default_filter : nil)
        query_filter  = active_filter.present? ? "(query: \"#{active_filter}\")" : ""

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

    end
  end
end
# :startdoc: