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

      # = Recursive Payload Sanitizer
      # Unwraps nested GraphQL edge/node/connection structures, flattens payload keys,
      # and strips out pageInfo metadata across any depth of the response tree.
      module PayloadSanitizer
        module_function

        # Recursively inspects incoming GraphQL data structures to flatten connection 
        # nodes and normalize string keys into underscored Ruby symbols/strings.
        #
        # === Parameters
        # * +payload+ [+Hash+/+Array+/+Object+] - Raw nested GraphQL response object.
        #
        # @return [Hash, Array, Object] Cleaned and flattened payload structure.
        #
        def sanitize(payload)
          case payload
          when Hash
            # 1. Unwrap GraphQL connection structures ({ "edges" => [{ "node" => ... }] })
            if payload.key?("edges") && payload["edges"].is_a?(Array)
              return payload["edges"].map { |edge| sanitize(edge["node"]) }.compact
            end

            # 2. Unwrap direct single node objects ({ "node" => { ... } })
            if payload.key?("node") && payload.keys.size == 1
              return sanitize(payload["node"])
            end

            # 3. Process key-value pairs recursively & normalize keys to underscored strings
            cleaned_hash = {}
            payload.each do |key, val|
              next if key == "pageInfo" # Omit GraphQL pagination cursors

              cleaned_hash[key.to_s.underscore] = sanitize(val)
            end
            cleaned_hash

          when Array
            payload.map { |item| sanitize(item) }.compact

          else
            # Primitive scalar values (String, Integer, Boolean, Float, Nil)
            payload
          end
        end
      end

      included do
        class_attribute :_graphql_single_endpoint, instance_writer: false
        class_attribute :_graphql_multiple_endpoint, instance_writer: false
        class_attribute :_graphql_mutation_endpoint, instance_writer: false
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
      # Supports standard single-node query generation as well as mutation execution syntax.
      #
      # === Parameters
      # * +use_mutation+ [+Boolean+] - Whether to compile a mutation operation rather than a query.
      #
      # @return [Array(String, Hash)] Tuple containing the executable GraphQL string and variables hash.
      #
      def build_graphql_request(use_mutation: false)
        endpoint_type = use_mutation ? :mutation : :single
        endpoint      = self.class.graphql_endpoint(endpoint_type) || self.class.graphql_endpoint(:single)
        query_fields  = self.class.graphql_query
        class_label   = self.class.name.demodulize
        op_type       = use_mutation ? "mutation" : "query"

        # Singleton endpoints in Shopify GraphQL (e.g. `shop`) do not take an `id` argument
        is_singleton  = endpoint.to_s == "shop"

        raw_id = if respond_to?(:shopify_id) && public_send(:shopify_id).present?
                  public_send(:shopify_id)
                elsif respond_to?(:id) && public_send(:id).present?
                  public_send(:id)
                end

        if is_singleton
          query = <<~GRAPHQL
            #{op_type} fetch#{class_label} {
              #{endpoint} {
                #{query_fields}
              }
            }
          GRAPHQL
          variables = {}
        elsif raw_id.present?
          formatted_gid = ensure_shopify_gid(raw_id, class_label)

          query = <<~GRAPHQL
            #{op_type} fetch#{class_label}($id: ID!) {
              #{endpoint}(id: $id) {
                #{query_fields}
              }
            }
          GRAPHQL
          variables = { id: formatted_gid }
        else
          raise ArgumentError, "Cannot execute single-resource GraphQL query for #{class_label}: `id` is missing or blank on #{inspect}."
        end

        [query, variables]
      end

      # Normalizes, sanitizes, transforms, and persists raw GraphQL response attributes directly onto 
      # the active record instance.
      #
      # Automatically resolves payload key across single queries, mutations, or generic root keys.
      #
      # === Parameters
      # * +response_data+ [+Hash+] - Raw root +data+ hash extracted from the GraphQL API response body.
      #
      # @return [ActiveRecord::Base] Self after attribute assignment and persistence.
      #
      def hydrate_from_graphql!(response_data)
        return self unless response_data.is_a?(Hash)

        # Look up payload target key across :single, :mutation, or fallback to first hash key
        single_ep   = self.class.graphql_endpoint(:single)
        mutation_ep = self.class.graphql_endpoint(:mutation)

        raw_payload = if single_ep && response_data.key?(single_ep)
                        response_data[single_ep]
                      elsif mutation_ep && response_data.key?(mutation_ep)
                        response_data[mutation_ep]
                      else
                        response_data.values.first || response_data
                      end

        return self unless raw_payload.is_a?(Hash)

        # 1. Recursively flatten edges/nodes and normalize key names
        sanitized_payload = PayloadSanitizer.sanitize(raw_payload)

        transforms           = self.class.graphql_attribute_transforms
        attributes_to_assign = {}

        # 2. Extract and assign scalar model columns only
        sanitized_payload.each do |key, value|
          attr_name = (key == "id" && respond_to?(:shopify_id=) && !respond_to?(:id=)) ? "shopify_id" : key

          # Guard against association collision or un-extracted child collections
          next if self.class.reflect_on_association(attr_name.to_sym) ||
                  self.class.reflect_on_association(attr_name.singularize.to_sym) ||
                  value.is_a?(Hash) ||
                  value.is_a?(Array)

          next unless respond_to?("#{attr_name}=")

          value = ensure_shopify_gid(value, self.class.name.demodulize) if attr_name == "shopify_id"

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

      private

      # Normalizes an incoming numeric or string ID into a fully qualified Shopify GraphQL 
      # Global ID (GID) string. Returns the string unmodified if it already features the +gid://shopify/+ scheme.
      #
      # === Parameters
      # * +id_val+ [+String+/+Integer+] - Raw database identifier, numeric string, or existing GID.
      # * +target_type+ [+String+] - Shopify GraphQL resource class type (e.g., +"Product"+, +"Shop"+).
      #
      # @return [String] Formatted GID string (e.g., +"gid://shopify/Product/12345"+).
      #
      def ensure_shopify_gid(id_val, target_type)
        return id_val.to_s if id_val.to_s.start_with?("gid://shopify/")

        "gid://shopify/#{target_type}/#{id_val}"
      end

      # Class methods mixed directly into the mounting ActiveRecord target model context.
      module ClassMethods
        # Registers the structural GraphQL connection endpoint tokens, filters, and payload schema 
        # selection blocks for the active model class structure.
        #
        # === Parameters
        # * +single+ [+String+/+Symbol+] - Optional single entry point (e.g., +:product+ or +:node+).
        # * +multiple+ [+String+/+Symbol+] - Optional list entry point (e.g., +:products+).
        # * +mutation+ [+String+/+Symbol+] - Optional mutation entry point (e.g., +:bulkOperationRunQuery+).
        # * +default_filter+ [+String+] - Optional default scope filter.
        # * +block+ [+Proc+] - Required block returning the field tree string.
        #
        # === Raises
        # * +ArgumentError+ - If no field selection block is supplied.
        #
        def expose_graphql(single: nil, multiple: nil, mutation: nil, default_filter: nil, &block)
          unless block
            raise ArgumentError, "A configuration block containing fields must be provided when calling expose_graphql on #{name}"
          end

          self._graphql_single_endpoint   = single&.to_s
          self._graphql_multiple_endpoint = multiple&.to_s
          self._graphql_mutation_endpoint = mutation&.to_s
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
        # * +type+ [+Symbol+] - Query endpoint type: +:single+, +:multiple+ (default), or +:mutation+.
        #
        # @return [String, nil]
        #
        def graphql_endpoint(type = :multiple)
          case type.to_sym
          when :single   then _graphql_single_endpoint
          when :mutation then _graphql_mutation_endpoint
          else _graphql_multiple_endpoint
          end
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