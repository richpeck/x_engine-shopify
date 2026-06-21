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
          raise ArgumentError, "A configuration block containing fields must be provided" unless block_given?

          self._graphql_single_endpoint = single&.to_s
          self._graphql_multiple_endpoint = multiple&.to_s
          self._graphql_default_filter = default_filter
          self._graphql_query_block = block
        end

        # Resolves the configured Shopify Admin GraphQL query entrypoint identifier string.
        # @return [String]
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

          _graphql_query_block.call.strip
        end
      end
    end
  end
end