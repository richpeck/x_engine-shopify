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
    # to a distinct parent Shopify Store tenant (+XEngine::Shopify::Shop+).
    #
    # == Architecture & Responsibilities
    # This model acts as a lightweight ActiveRecord persistence layer for webhook states.
    # Remote network synchronization (GraphQL subscriptions and cleanup) is handled 
    # explicitly by reconciliation operations (e.g., +XInventory::Operations::Shopify::SyncWebhooks+).
    #
    # == Registry Decoration
    # Bridges database records with immutable registry metadata defined in
    # +XEngine::Shopify::Webhooks::Registry+. Access metadata via +#config+, 
    # +#workflow_intent+, or +#graphql_enum+.
    #
    # == Status Management
    # Managed via standard ActiveRecord enum:
    # * +disabled+ (Initial State): Unsubscribed locally or removed from remote platform.
    # * +active+: Remote Shopify subscription active and verified.
    # * +failing+: Synchronization error or delivery exception recorded.
    #
    # == Database Schema
    # Matches +shopify_webhooks+ table layout:
    # * +id+ [+String+] - Primary key (UUID/String identifier).
    # * +shop_id+ [+String+] - Foreign key to +XEngine::Shopify::Shop+.
    # * +shopify_id+ [+String+] - Remote Shopify Webhook Subscription GID.
    # * +topic+ [+String+] - Lowercase wire topic identifier (e.g., +"products/update"+).
    # * +status+ [+String+] - Current state (+disabled+, +active+, +failing+). Default: +"disabled"+.
    # * +fields+ [+String+] - Serialized JSON array of targeted GraphQL selection fields.
    # * +filter+ [+String+] - Optional Shopify query filter string.
    # * +name+ [+String+] - Human-readable label for configuration displays.
    # * +notes+ [+Text+] - Logging buffer for runtime errors, warnings, or audit records.
    #
    class Webhook < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # ---
      # :section: Status Enum
      # ---

      enum :status, {
        disabled: "disabled",
        active:   "active",
        failing:  "failing"
      }, default: "disabled"

      # ---
      # :section: Serialization
      # ---

      # Handles JSON array encoding for SQLite3/PostgreSQL string column compatibility
      serialize :fields, coder: JSON, default: []

      # ---
      # :section: GraphQL Serialization Layouts
      # ---

      expose_graphql single: :webhook_subscription, multiple: :webhook_subscriptions do
        <<~GRAPHQL
          __typename
          id
          legacy_id: legacyResourceId
          name
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
      # :section: Associations
      # ---

      # @!attribute [rw] shop
      #   @return [XEngine::Shopify::Shop] Parent store tenant owning this webhook.
      belongs_to :shop, 
                 foreign_key: :shop_id, 
                 class_name: "XEngine::Shopify::Shop", 
                 inverse_of: :webhooks

      # ---
      # :section: Validations
      # ---

      validates :shop, :status, presence: true

      # Enforce unique remote Shopify GIDs across all database webhooks when present
      validates :shopify_id, 
                uniqueness: { allow_nil: true, message: "must be unique across all webhooks." }

      # Multi-tenant isolation: Only one unique subscription per topic per shop instance
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
      # :section: Registry Delegations
      # ---

      # Delegates registry properties directly to the underlying topic configuration object.
      delegate :workflow_intent, :graphql_enum, to: :config, allow_nil: true

      # ---
      # :section: Instance Methods
      # ---

      # Resolves the type-safe configuration blueprint matching this record's topic.
      #
      # === Returns
      # * +XEngine::Shopify::Webhooks::Registry::TopicConfig+ or +nil+
      #
      def config
        @config ||= XEngine::Shopify::Webhooks::Registry.find(topic)
      end
    end
  end
end
# :startdoc: