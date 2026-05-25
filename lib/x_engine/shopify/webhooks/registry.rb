# :stopdoc:
################################################################
################################################################
##   ___       __   _______   ________  ___  ___  ________  ________  ___  __            ________  _______   ________  ___  ________  _________  ________      ___    ___ 
##  |\  \     |\  \|\  ___ \ |\   __  \|\  \|\  \|\   __  \|\   __  \|\  \|\  \         |\   __  \|\  ___ \ |\   ____\|\  \|\   ____\|\___   ___\\   __  \    |\  \  /  /|
##  \ \  \    \ \  \ \   __/|\ \  \|\ /\ \  \\\  \ \  \|\  \ \  \|\  \ \  \/  /|_       \ \  \|\  \ \   __/|\ \  \___|\ \  \ \  \___|\|___ \  \_\ \  \|\  \   \ \  \/  / /
##   \ \  \  __\ \  \ \  \_|/_\ \   __  \ \   __  \ \  \\\  \ \  \\\  \ \   ___  \       \ \   _  _\ \  \_|/_\ \  \  __\ \  \ \_____  \   \ \  \ \ \   _  _\   \ \    / / 
##    \ \  \|\__\_\  \ \  \_|\ \ \  \|\  \ \  \ \  \ \  \\\  \ \  \\\  \ \  \\ \  \       \ \  \\  \\ \  \_|\ \ \  \|\  \ \  \|____|\  \   \ \  \ \ \  \\  \|   \/  /  /  
##     \ \____________\ \_______\ \_______\ \__\ \__\ \_______\ \_______\ \__\\ \__\       \ \__\\ _\\ \_______\ \_______\ \__\____\_\  \   \ \__\ \ \__\\ _\ __/  / /    
##      \|____________|\|_______|\|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|        \|__|\|__|\|_______|\|_______|\|__|\_________\   \|__|  \|__|\|__|\___/ /     
##                                                                                                                            \|_________|                   \|___|/      
##  --
##  RPECK 22/04/2026 - Webhook Topic Registry
##  Provides the means to interface with the topics that we can use within the app
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "dry-types"
require "dry-struct"

module XEngine
  module Shopify
    module Webhooks
      # = Shopify Webhooks Registry (Dry-Powered with GraphQL Mapping)
      #
      # Centralized structural registry managing configuration schema types,
      # workflow engine intents, and translation keys bridging HTTP wire headers
      # with Shopify Admin GraphQL API mutation enums.
      class Registry
        
        # ---
        # :section: Type Matrix Definitions
        # ---
        module Types
          include Dry.Types()
        end

        # Strict configuration blueprint for validating registered topics
        class TopicConfig < Dry::Struct
          # The lowercase HTTP wire token (e.g., "products/update")
          attribute :topic,           Types::String

          # The official Shopify Admin GraphQL Enum string (e.g., "PRODUCTS_UPDATE")
          attribute :graphql_enum,    Types::String

          attribute :name,            Types::String
          attribute :workflow_intent, Types::String
          attribute :introduced_in,   Types::String.default("2023-01")

          # Optional data footprint minimization rules
          attribute? :default_filter, Types::String.optional
          attribute? :required_fields, Types::Array.of(Types::String).default { [].freeze }
        end

        # ---
        # :section: Master Configuration Catalog
        # ---
        DEFINITIONS = {
          # Bulk Compilation Lifecycle
          "bulk_operations/finish" => TopicConfig.new(
            topic: "bulk_operations/finish",
            graphql_enum: "BULK_OPERATIONS_FINISH",
            name: "Bulk Operation Compilation Completed",
            workflow_intent: "models.shopify_webhook.bulk_operations_finish"
          ),

          # Order Ledger Lifecycle
          "orders/create" => TopicConfig.new(
            topic: "orders/create",
            graphql_enum: "ORDERS_CREATE",
            name: "Live Order Placed",
            workflow_intent: "models.shopify_webhook.orders_create"
          ),
          "orders/updated" => TopicConfig.new(
            topic: "orders/updated",
            graphql_enum: "ORDERS_UPDATED",
            name: "Order State Modified",
            workflow_intent: "models.shopify_webhook.orders_updated"
          ),
          "orders/delete" => TopicConfig.new(
            topic: "orders/delete",
            graphql_enum: "ORDERS_DELETE",
            name: "Order Removed from System",
            workflow_intent: "models.shopify_webhook.orders_delete"
          ),

          # Financial Transaction Sub-Systems
          "order_transactions/create" => TopicConfig.new(
            topic: "order_transactions/create",
            graphql_enum: "ORDER_TRANSACTIONS_CREATE",
            name: "Payment Gateway Transaction Captured",
            workflow_intent: "models.shopify_webhook.order_transactions_create"
          ),
          "refunds/create" => TopicConfig.new(
            topic: "refunds/create",
            graphql_enum: "REFUNDS_CREATE",
            name: "Refund Allocation Processed",
            workflow_intent: "models.shopify_webhook.refunds_create"
          ),

          # Product Resource Catalog Lifecycle
          "products/create" => TopicConfig.new(
            topic: "products/create",
            graphql_enum: "PRODUCTS_CREATE",
            name: "New Product Initialized",
            workflow_intent: "models.shopify_webhook.products_create"
          ),
          "products/update" => TopicConfig.new(
            topic: "products/update",
            graphql_enum: "PRODUCTS_UPDATE",
            name: "Product Attribute Mutation",
            workflow_intent: "models.shopify_webhook.products_update"
          ),
          "products/delete" => TopicConfig.new(
            topic: "products/delete",
            graphql_enum: "PRODUCTS_DELETE",
            name: "Product Purged from Inventory",
            workflow_intent: "models.shopify_webhook.products_delete"
          ),

          # Custom and Smart Collections
          "collections/create" => TopicConfig.new(
            topic: "collections/create",
            graphql_enum: "COLLECTIONS_CREATE",
            name: "Category Collection Created",
            workflow_intent: "models.shopify_webhook.collections_create"
          ),
          "collections/update" => TopicConfig.new(
            topic: "collections/update",
            graphql_enum: "COLLECTIONS_UPDATE",
            name: "Category Collection Modified",
            workflow_intent: "models.shopify_webhook.collections_update"
          ),
          "collections/delete" => TopicConfig.new(
            topic: "collections/delete",
            graphql_enum: "COLLECTIONS_DELETE",
            name: "Category Collection Erased",
            workflow_intent: "models.shopify_webhook.collections_delete"
          )
        }.freeze

        class << self
          
          # Returns an array containing every supported string topic key for ActiveRecord inclusion hooks.
          # @return [Array<String>]
          def all_topics
            DEFINITIONS.keys
          end

          # Resolves a configuration struct by its standard lowercase wire identifier (e.g. "products/update").
          # @param topic [String]
          # @return [TopicConfig, nil]
          def find(topic)
            DEFINITIONS[topic]
          end

          # Resolves a configuration struct looking backwards using the GraphQL Enum token (e.g. "PRODUCTS_UPDATE").
          # @param enum_string [String]
          # @return [TopicConfig, nil]
          def find_by_enum(enum_string)
            DEFINITIONS.values.find { |config| config.graphql_enum == enum_string }
          end

          # Verifies whether an inbound string topic is actively registered within the platform ecosystem.
          # @param topic [String]
          # @return [Boolean]
          def supported?(topic)
            DEFINITIONS.key?(topic)
          end

          # Defensive guard check: Evaluates if a given topic is structurally compatible 
          # with a specific store's locked API version configuration.
          def compatible?(topic, current_version)
            return false unless supported?(topic)
            
            introduced_val = find(topic).introduced_in.delete("-").to_i
            current_val    = current_version.delete("-").to_i

            current_val >= introduced_val
          end
        end

      end
    end
  end
end