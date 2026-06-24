# :stopdoc:
################################################################
################################################################
##   ___       __   _______   ________  ___  ___  ________  ________  ___  __       
##  |\  \     |\  \|\  ___ \ |\   __  \|\  \|\  \|\   __  \|\   __  \|\  \|\  \     
##  \ \  \    \ \  \ \   __/|\ \  \|\ /\ \  \\\  \ \  \|\  \ \  \|\  \ \  \/  /|_   
##   \ \  \  __\ \  \ \  \_|/_\ \   __  \ \   __  \ \  \\\  \ \  \\\  \ \   ___  \  
##    \ \  \|\__\_\  \ \  \_|\ \ \  \|\  \ \  \ \  \ \  \\\  \ \  \\\  \ \  \\ \  \ 
##     \ \____________\ \_______\ \_______\ \__\ \__\ \_______\ \_______\ \__\\ \__\
##      \|____________|\|_______|\|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|
##  --
##  RPECK 22/06/2026 - Shopify Webhook Subscription Model
##  Manages multi-tenant event endpoint routing configurations
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Webhook Model
    #
    # Represents a state-aware webhook endpoint subscription profile mapped 
    # to a distinct parent Shopify Store tenant.
    #
    # == Registry Decoration
    # This model bridges relational database states with immutable structural 
    # capabilities defined inside the +XEngine::Shopify::Webhooks::Registry+ class.
    # Calling #config opens access to high-level system metadata such as the 
    # official GraphQL Enum translation values and core Workflow Engine execution intents.
    #
    # == Lifecycle Integration
    # This resource encapsulates its GraphQL representation layouts natively via 
    # +XEngine::Shopify::HasGraphQLRepresentation+. Handles and identifiers are 
    # preserved directly from incoming platform payloads.
    #
    class Webhook < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # ---
      # :section: Serialization Abstractions
      # ---

      # Handle SQLite3 structural fallback limitations automatically if native array mutations are dropped
      serialize :fields, type: JSON, default: []

      # ---
      # :section: Stackable Configuration
      # ---

      # Expose the webhook resource configurations using Shopify's native tracking identifier.
      expose_as :shopify_webhooks, 
                slug: :webhooks,
                identity: :shopify_id,
                actions: [:read, :create, :update, :destroy],
                member_actions: { sync: :post }

      # == GraphQL Layout Declarations
      # Binds endpoints, custom selection fragments, and default pipeline filters.
      expose_graphql single: :webhook_subscription, multiple: :webhook_subscriptions do
        <<~GRAPHQL
          __typename
          id
          legacy_id: legacyResourceId
          topic
          includeFields
          created_at: createdAt
          api_version: apiVersion {
            displayName 
            handle
          }
          endpoint {
            __typename
            ... on WebhookHttpEndpoint {
              callbackUrl
            }
          }
        GRAPHQL
      end

      # ---
      # :section: Enums
      # ---

      # Map string-backed enums to generate optimized query scopes and performance predicates
      enum :status, {
        active:   "active",
        disabled: "disabled",
        failing:  "failing"
      }, default: :disabled

      # ---
      # :section: Associations
      # ---
      
      # The parent store tenant owning this webhook subscription configuration.
      belongs_to :shop, 
                 foreign_key: :shop_id, 
                 class_name: "XEngine::Shopify::Shop", 
                 inverse_of: :webhooks

      # ---
      # :section: Validations
      # ---

      validates :shop, :status, presence: true
      
      # Enforce strict multi-tenant isolation boundaries. Only one unique 
      # subscription row can exist per topic on any single storefront instance.
      validates :topic, 
                presence: true, 
                uniqueness: { 
                  scope: :shop_id, 
                  message: "subscription already exists for this store tenant." 
                },
                inclusion: { 
                  in: ->(_) { XEngine::Shopify::Webhooks::Registry.all_topics },
                  message: ->(_, data) { "'#{data[:value]}' is not a supported target for the engine pipeline infrastructure." }
                }

      # ---
      # :section: Instance Methods
      # ---

      # Resolves the type-safe, dry-struct configuration blueprint instance matching 
      # this record's lowercase wire string topic lookup key.
      #
      # === Returns
      # * +XEngine::Shopify::Webhooks::Registry::TopicConfig+
      #
      def config
        @config ||= XEngine::Shopify::Webhooks::Registry.find(topic)
      end

      # Convenience helper delegation pulling the specific target Workflow Engine 
      # pipeline string code directly out of the application registry block.
      #
      # === Returns
      # * +String+:: e.g., +"models.shopify_webhook.products_update"+
      #
      def workflow_intent
        config&.workflow_intent
      end

      # Convenience helper delegation pulling the explicit uppercase screaming snake 
      # case string used by the outgoing GraphQL Admin mutation matrix.
      #
      # === Returns
      # * +String+:: e.g., +"PRODUCTS_UPDATE"+
      #
      def graphql_enum
        config&.graphql_enum
      end

    end
  end
end
# :startdoc: