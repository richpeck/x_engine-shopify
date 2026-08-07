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
    # target endpoints, default filters, and query selection schemas explicitly.
    #
    module HasGraphQLRepresentation
      extend ActiveSupport::Concern

      included do
        class_attribute :_graphql_single_endpoint, instance_writer: false
        class_attribute :_graphql_multiple_endpoint, instance_writer: false
        class_attribute :_graphql_default_filter, instance_writer: false
        class_attribute :_graphql_query_block, instance_writer: false
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
        def expose_graphql(single: nil, multiple: nil, default_filter: nil, &block)
          unless block
            raise ArgumentError, "A configuration block containing fields must be provided when calling expose_graphql on #{name}"
          end

          self._graphql_single_endpoint = single&.to_s
          self._graphql_multiple_endpoint = multiple&.to_s
          self._graphql_default_filter = default_filter
          self._graphql_query_block = block
        end

        # Syntactic sugar for nested GraphQL fragments/sub-queries that do not have
        # standalone single or multiple root endpoints.
        #
        # === Parameters
        # * +block+ [+Proc+] - Required block returning the selection field payload.
        #
        def graphql_fragment(&block)
          unless block
            raise ArgumentError, "A configuration block containing fields must be provided when calling graphql_fragment on #{name}"
          end

          expose_graphql(&block)
        end

        # Resolves the configured Shopify Admin GraphQL query entrypoint identifier string.
        # @return [String, nil]
        def graphql_endpoint(type = :multiple)
          type.to_sym == :single ? _graphql_single_endpoint : _graphql_multiple_endpoint
        end

        # Resolves the default Shopify API query filter string context if declared.
        # @return [String, nil]
        def graphql_default_filter
          _graphql_default_filter
        end

        # Evaluates the internal macro block composition, compiling and returning 
        # the literal multiline GraphQL field payload string.
        # @return [String]
        def graphql_query
          return "" unless _graphql_query_block

          _graphql_query_block.call.to_s.strip
        end

        # Fetches remote GraphQL nodes by ID via the shop client and persists/hydrates local records.
        #
        # @param shop [XEngine::Shopify::Shop] Target store instance
        # @param ids [Array<String, Integer>] Array of node IDs or GIDs
        # @return [Array<XEngine::Core::Model>]
        def sync_nodes_from_shopify(shop:, ids:)
          formatted_gids = Array(ids).flatten.compact.map do |id|
            id.to_s.start_with?("gid://") ? id.to_s : "gid://shopify/#{name.demodulize}/#{id}"
          end

          return [] if formatted_gids.empty?

          gql_query = <<~GRAPHQL
            query getNodes($ids: [ID!]!) {
              nodes(ids: $ids) {
                ... on #{name.demodulize} {
                  #{graphql_query}
                }
              }
            }
          GRAPHQL

          response = shop.graphql_client.query(
            query: gql_query,
            variables: { ids: formatted_gids }
          )

          nodes = response.body.dig("data", "nodes") || []
          
          nodes.compact.map do |node_data|
            record = shop.public_send(name.demodulize.underscore.pluralize).find_or_initialize_by(
              shopify_id: node_data["id"]
            )
            
            # Filter and assign mapped remote GraphQL attributes
            assignable_attrs = node_data.except("__typename", "id").transform_keys(&:underscore)
            valid_keys = record.attribute_names
            
            record.assign_attributes(assignable_attrs.slice(*valid_keys))
            record.tap(&:save!)
          end
        end
      end
    end
  end
end