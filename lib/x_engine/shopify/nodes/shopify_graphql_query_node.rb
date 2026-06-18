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
##  RPECK 07/06/2026 - Shopify GraphQL Interactor Node
##  Provides a data-driven GraphQL execution vector for workflow engines.
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Workflow
    module Nodes
      # = Shopify GraphQL Interactor Node
      #
      # Encapsulates API mutations, structural harvesting queries, and multi-tenant bulk download
      # initializations executing directly against the active Shopify Admin API GraphQL gateway.
      #
      # This node reads raw string templates from structured JSON/YAML workflow configurations and
      # handles structural parameter rendering via double-mustache evaluation hooks.
      #
      # == Context Requirements
      # The open Interactor state requires the following parameters at runtime:
      # * <tt>context.shop_id</tt> - The database primary key identifier of the target Shop storefront.
      # * <tt>context.node_options</tt> - A dictionary configuration block parsed from a Workflow layout file.
      #   * <tt>:query</tt> - The raw GraphQL query or mutation string template containing optional mustache attributes.
      #   * <tt>:variables</tt> - (Optional) A key-value map representing native GraphQL query parameters.
      #
      # == Outputs
      # Upon a successful execution block, it appends the following parameters to the context stream:
      # * <tt>context.last_graphql_response</tt> - A parsed Hash tracking the raw JSON payload body returned by the gateway.
      #
      # == Sample Workflow Node Usage (YAML Data Schema)
      #
      #   id: "fetch_products_node"
      #   type: "ShopifyGraphqlNode"
      #   options:
      #     query: |
      #       query GetProducts($limit: Int!) {
      #         products(first: $limit, query: "{{ filters }}") {
      #           edges { node { id title } }
      #         }
      #       }
      #     variables:
      #       limit: 250
      #
      class ShopifyGraphQLNode
        include Interactor

        # Executes the operational GraphQL request transaction pipeline.
        #
        # Verifies the presence of required environmental parameters, applies 
        # variable token interpolations, dispatches the HTTP envelope via the 
        # pre-authenticated client wrapper matrix, and monitors downstream failures.
        #
        # @raise [ActiveRecord::RecordNotFound] If the context shop_id maps to a missing row block.
        # @return [void]
        def call
          # 1. Assert input presence to fail early if the pipeline configuration is broken
          context.fail!(error: "Missing required shop reference context.") if context.shop_id.blank?
          context.fail!(error: "Missing explicit workflow node options configuration.") if context.node_options.blank?

          # 2. Resolve target store isolation context
          shop = XEngine::Shopify::Shop.find(context.shop_id)

          # 3. Pull query schema template and execute liquid-style variable injection
          query_template = context.node_options[:query]
          interpolated_query = interpolate_variables(query_template, context)

          # 4. Fire the remote query using the shop's pre-authenticated client matrix wrapper
          response = shop.graphql_client.query(
            query: interpolated_query, 
            variables: context.node_options[:variables] || {}
          )

          # 5. Intercept API errors or user mutation exceptions
          if response.body.dig("errors").present? || response.body.dig("data", "node", "userErrors")&.any?
            context.fail!(
              error: "Shopify GraphQL execution error detected",
              response_details: response.body
            )
          else
            # 6. Pipe the returned payload back into the interactor chain for downstream nodes
            context.last_graphql_response = response.body
          end
        rescue ActiveRecord::RecordNotFound => e
          context.fail!(error: "Target store record matching ID #{context.shop_id} could not be resolved: #{e.message}")
        rescue => e
          context.fail!(error: "Unexpected structural node crash: #{e.message}")
        end

        private

        # Inspects structural query blocks for double-mustache parameters and swaps them out
        # dynamically using data values saved across the open Interactor context registry.
        #
        # Given a template string like <tt>"{ products(query: \"{{ filters }}\") }"</tt> and a context parameter 
        # of <tt>context.filters = "status:active"</tt>, this routine computes the parsed variant safely.
        #
        # @param template [String] The raw un-interpolated GraphQL query template text block.
        # @param ctx [Interactor::Context] The open state tracking dictionary payload.
        # @return [String] The fully interpolated GraphQL query ready for transmission.
        #
        def interpolate_variables(template, ctx)
          return "" if template.blank?

          template.gsub(/\{\{\s*(\w+)\s*\}\}/) do
            token = $1
            # Check context fields natively first, fall back to string/symbol key scanning
            ctx.public_send(token) || ctx[token.to_sym] || ctx[token.to_s] || ""
          end
        end

      end
    end
  end
end