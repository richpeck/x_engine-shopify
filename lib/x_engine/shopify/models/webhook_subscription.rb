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
    # Mapped to a distinct parent Shopify Store tenant (+XEngine::Shopify::Shop+).
    #
    # == Architecture & Responsibilities
    # This model acts as an ActiveRecord persistence layer for webhook states.
    # Remote platform registration, unregistration, and dashboard schema configurations
    # are declared via engine extensions.
    #
    # == Status Management
    # Managed via standard ActiveRecord enum:
    # * +disabled+ (Initial State): Unsubscribed locally or removed from remote platform.
    # * +active+: Remote Shopify subscription active and verified.
    # * +failing+: Synchronization error or delivery exception recorded.
    #
    # == Database Schema
    # Matches +shopify_webhooks+ table layout:
    # * +id+ [+String+] - Primary key (Remote Shopify Webhook Subscription GID).
    # * +shop_id+ [+String+] - Foreign key to +XEngine::Shopify::Shop+.
    # * +topic+ [+String+] - Lowercase wire topic identifier (e.g., +"products/update"+).
    # * +status+ [+String+] - Current state (+disabled+, +active+, +failing+). Default: +"disabled"+.
    # * +fields+ [+String+] - Serialized JSON array of targeted GraphQL selection fields.
    # * +filter+ [+String+] - Optional Shopify query filter string.
    # * +name+ [+String+] - Human-readable label for configuration displays.
    # * +notes+ [+Text+] - Logging buffer for runtime errors, warnings, or audit records.
    #
    class WebhookSubscription < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # ---
      # :section: Serialization
      # ---

      # Handles JSON array encoding for SQLite3/PostgreSQL string column compatibility
      serialize :fields, coder: JSON, default: []

      # ---
      # :section: GraphQL Serialization Layouts
      # ---

      # Exposes local model attributes back to GraphQL nodes when fetching webhook state.
      expose_graphql single: :node, multiple: :nodes do
        <<~GRAPHQL
          __typename
          id
          ... on WebhookSubscription {
            id
            name
            topic
            filter
            uri
            fields: includeFields
            created_at: createdAt
            api_version: apiVersion {
              displayName 
              handle
            }
          }
        GRAPHQL
      end

      # ---
      # :section: Associations
      # ---

      # Parent store tenant owning the execution context for this webhook subscription.
      belongs_to :shop, 
                 foreign_key: :shop_id, 
                 class_name: "XEngine::Shopify::Shop", 
                 inverse_of: :webhook_subscriptions

      # ---
      # :section: Validations
      # ---

      # Primary key ID must be present on update once saved/synced with Shopify
      validates :id, presence: true, on: :update

      # Multi-tenant isolation: Only one unique subscription per topic per shop instance
      validates :topic, 
                uniqueness: { 
                  scope: :shop_id, 
                  message: "subscription already exists for this store tenant." 
                }

      # ---
      # :section: Instance Methods
      # ---

      # Formats the topic string into Shopify's upper-cased GraphQL Enum representation.
      #
      # === Returns
      # * [+String+, +nil+] Upper-cased string suitable for GQL variables (e.g., +"PRODUCTS_UPDATE"+).
      #
      def graphql_topic_enum
        topic.to_s.tr("/", "_").upcase.presence
      end

      # Sanitizes the internal display +name+ into a handleized format containing only lowercase 
      # alphanumeric characters, underscores, and hyphens to satisfy Shopify API input validation.
      #
      # === Returns
      # * [+String+, +nil+] Parameterized name string (e.g., +"my_webhook_store"+).
      #
      def graphql_name
        return if name.blank?

        name.to_s
            .parameterize(separator: "_")
            .gsub(/[^a-zA-Z0-9_-]/, "")
      end
    end
  end
end