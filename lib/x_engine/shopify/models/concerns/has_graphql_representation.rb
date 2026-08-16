# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  ________  ___  ___  ________  ___          
##  |\   ____\|\   __  \|\   __  \|\   __  \|\  \|\  \|\   __  \|\  \         
##  \ \  \___|\ \  \|\  \ \  \|\  \ \  \|\  \ \  \\\  \ \  \|\  \ \  \        
##   \ \  \  __\ \   _  _\ \   __  \ \   ____\ \   __  \ \  \\\  \ \  \       
##    \ \  \|\  \ \  \\  \\ \  \ \  \ \  \___|\ \  \ \  \ \  \\\  \ \  \____  
##     \ \_______\ \__\\ _\\ \__\ \__\ \__\    \ \__\ \__\ \_____  \ \_______\
##      \|_______|\|__|\|__|\|__|\|__|\|__|     \|__|\|__|\|___| \__\|_______|
##                                                              \|__|                                                                          
##  --
##  RPECK 20/06/2026 - HasGraphQLRepresentation Concern
##  Provides a robust DSL for defining unified API endpoints and query schemas.
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify HasGraphQLRepresentation Concern
    #
    # Provides a clean, standardized macro-driven Domain Specific Language (DSL) 
    # allowing database models to declare their external Shopify Admin GraphQL API 
    # target endpoints, default filters, query selection schemas, and attribute 
    # type transformations.
    #
    # Additionally provides instance-level execution methods required by sync pipeline 
    # nodes (e.g., +XInventory::Nodes::Shopify::ResyncNode+) to dynamically construct 
    # outbound GraphQL request payloads and hydrate model state from raw API response data.
    #
    module HasGraphQLRepresentation
      extend ActiveSupport::Concern

      included do
        class_attribute :_graphql_single_endpoint, instance_writer: false
        class_attribute :_graphql_multiple_endpoint, instance_writer: false
        class_attribute :_graphql_default_filter, instance_writer: false
        class_attribute :_graphql_query_block, instance_writer: false
        class_attribute :_graphql_attribute_transforms, instance_writer: false, default: {}
      end

      # ---
      # :section: Instance Sync Interface Methods
      # ---

      # Dynamically compiles the full GraphQL query document and variable payload hash 
      # required to sync this specific record instance from Shopify.
      #
      # Supports both resource-specific ID lookups (e.g., +node(id: $id)+ / +product(id: $id)+) 
      # and direct root singletons (e.g., +shop+).
      #
      # @return [Array(String, Hash)] Tuple containing the executable GraphQL query string and variables hash.
      #
      # @example Resource instance with shopify_id
      #   product.build_graphql_request
      #   # => ["query fetchProduct($id: ID!) { product(id: $id) { id title } }", { id: "gid://shopify/Product/123" }]
      #
      # @example Root singleton instance (Shop)
      #   shop.build_graphql_request
      #   # => ["query fetchShop { shop { id name email } }", {}]
      #
      def build_graphql_request
        endpoint     = self.class.graphql_endpoint(:single)
        query_fields = self.class.graphql_query
        class_label  = self.class.name.demodulize

        if respond_to?(:shopify_id) && shopify_id.present?
          query = <<~GRAPHQL
            query fetch#{class_label}($id: ID!) {
              #{endpoint}(id: $id) {
                #{query_fields}
              }
            }
          GRAPHQL
          variables = { id: shopify_id }
        else
          query = <<~GRAPHQL
            query fetch#{class_label} {
              #{endpoint} {
                #{query_fields}
              }
            }
          GRAPHQL
          variables = {}
        end

        [query, variables]
      end

      # Normalizes, transforms, and persists raw GraphQL response attributes directly onto 
      # the active record instance.
      #
      # Keys from the payload are underscored to align with Rails column naming conventions, 
      # and coerced according to declared +graphql_attribute_transforms+.
      #
      # @param response_data [Hash] Raw root +data+ hash extracted from the GraphQL API response body.
      # @return [ActiveRecord::Base] Self after attribute assignment and persistence.
      #
      def hydrate_from_graphql!(response_data)
        endpoint = self.class.graphql_endpoint(:single)
        payload  = response_data[endpoint]

        return self unless payload.is_a?(Hash)

        transforms           = self.class.graphql_attribute_transforms
        attributes_to_assign = {}

        payload.each do |key, value|
          attr_name = key.to_s.underscore
          next unless respond_to?("#{attr_name}=")

          transform = transforms[attr_name.to_sym]
          transformed_value = case transform
                              when Symbol then value.public_send(transform) rescue value
                              when Proc   then transform.call(value)
                              else value
                              end

          attributes_to_assign[attr_name] = transformed_value
        end

        assign_attributes(attributes_to_assign)
        save! if changed?
        self
      end

      # Class methods mixed directly into the mounting ActiveRecord target model context.
      module ClassMethods
        # Registers the structural GraphQL connection endpoint tokens, filters, and payload schema 
        # selection blocks for the active model class structure.
        #
        # === Parameters
        # * +single+ [+String+/+Symbol+] - Optional single entry point (e.g., +:product+).
        # * +multiple+ [+String+/+Symbol+] - Optional list entry point (e.g., +:products+).
        # * +default_filter+ [+String+] - Optional default scope filter.
        # * +block+ [+Proc+] - Required block returning the field tree string.
        #
        # === Raises
        # * +ArgumentError+ - If no field selection block is supplied.
        #
        def expose_graphql(single: nil, multiple: nil, default_filter: nil, &block)
          unless block
            raise ArgumentError, "A configuration block containing fields must be provided when calling expose_graphql on #{name}"
          end

          self._graphql_single_endpoint   = single&.to_s
          self._graphql_multiple_endpoint = multiple&.to_s
          self._graphql_default_filter    = default_filter
          self._graphql_query_block       = block
        end

        # Syntactic sugar for nested GraphQL fragments/sub-queries that do not have
        # standalone single or multiple root endpoints.
        #
        # === Parameters
        # * +block+ [+Proc+] - Required block returning the selection field payload.
        #
        # === Raises
        # * +ArgumentError+ - If no field selection block is supplied.
        #
        def graphql_fragment(&block)
          unless block
            raise ArgumentError, "A configuration block containing fields must be provided when calling graphql_fragment on #{name}"
          end

          expose_graphql(&block)
        end

        # Macro to declare field type coercion rules for attributes normalized 
        # from GraphQL responses into ActiveRecord database columns.
        #
        # === Parameters
        # * +transforms+ [+Hash+] - Key-value pairs mapping attribute names to transform types/procs.
        #
        # === Example
        #   graphql_attribute_transforms(
        #     status: :downcase,
        #     file_size: :to_i,
        #     created_at: :to_time
        #   )
        #
        # @return [Hash] Configured attribute transforms mapping.
        #
        def graphql_attribute_transforms(transforms = nil)
          if transforms
            self._graphql_attribute_transforms = _graphql_attribute_transforms.merge(transforms.symbolize_keys)
          end

          _graphql_attribute_transforms
        end

        # Resolves the configured Shopify Admin GraphQL query entrypoint identifier string.
        #
        # === Parameters
        # * +type+ [+Symbol+] - Query endpoint type, either +:single+ or +:multiple+ (default).
        #
        # @return [String, nil]
        #
        def graphql_endpoint(type = :multiple)
          type.to_sym == :single ? _graphql_single_endpoint : _graphql_multiple_endpoint
        end

        # Resolves the default Shopify API query filter string context if declared.
        #
        # @return [String, nil]
        #
        def graphql_default_filter
          _graphql_default_filter
        end

        # Evaluates the internal macro block composition, compiling and returning 
        # the literal multiline GraphQL field payload string.
        #
        # @return [String]
        #
        def graphql_query
          return "" unless _graphql_query_block

          _graphql_query_block.call.to_s.strip
        end
      end
    end
  end
end