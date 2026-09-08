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
    # This model acts as an ActiveRecord persistence layer for webhook states.
    # Synchronization, mutation dispatching, and topic resolution are handled 
    # dynamically via the engine's GraphQL representation and resync system.
    #
    # == Dual-Mode Request Dispatch
    # Like +BulkOperation+, this model implements a dual dispatch lifecycle via +#build_graphql_request+:
    # 1. *Un-synced (+shopify_id.blank?+):* Dispatches the +webhookSubscriptionCreate+ 
    #    mutation payload along with the required topic, URI, fields, filter, and handleized name.
    # 2. *Synced (+shopify_id.present?+):* Delegates to standard +HasGraphQLRepresentation+ 
    #    to execute node status queries via +node(id: $id)+.
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

      # Exposes local model attributes back to GraphQL nodes when fetching or mutating webhook state.
      expose_graphql single: :node, multiple: :nodes, mutation: "webhookSubscriptionCreate" do
        <<~GRAPHQL
          __typename
          id
          ... on WebhookSubscription {
            id
            shopify_id: id
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

      # Enforce unique remote Shopify GIDs across all database webhooks when present
      validates :shopify_id, 
                uniqueness: { allow_nil: true, message: "must be unique across all webhooks." }

      # Multi-tenant isolation: Only one unique subscription per topic per shop instance
      validates :topic, 
                uniqueness: { 
                  scope: :shop_id, 
                  message: "subscription already exists for this store tenant." 
                }

      # ---
      # :section: Instance Methods
      # ---

      # Dynamically determines the appropriate GraphQL request payload depending on local record state.
      #
      # When unsourced (+shopify_id+ is blank), constructs the +webhookSubscriptionCreate+ 
      # mutation to register the endpoint on Shopify.
      #
      # When sourced (+shopify_id+ is present), delegates to +HasGraphQLRepresentation#build_graphql_request+
      # to fetch the existing node state from Shopify via +node(id: $id)+.
      #
      # === Returns
      # * [+Array(String, Hash)+] A tuple containing the GraphQL document string and variable bindings hash.
      #
      # === Examples
      #   webhook.build_graphql_request
      #   # => ["mutation WebhookSubscriptionCreate($topic: ...", { topic: "PRODUCTS_UPDATE", subscription: { ... } }]
      #
      def build_graphql_request
        if shopify_id.blank?
          build_creation_mutation
        else
          super # Delegates to HasGraphQLRepresentation standard query generator
        end
      end

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
      # === Examples
      #   webhook.name = "My Webhook @ Store!"
      #   webhook.graphql_name
      #   # => "my_webhook_store"
      #
      def graphql_name
        return if name.blank?

        name.to_s
            .parameterize(separator: "_")
            .gsub(/[^a-zA-Z0-9_-]/, "")
      end

      private

      # Generates the +webhookSubscriptionCreate+ GraphQL mutation tuple for creating a subscription on Shopify.
      #
      # === Returns
      # * [+Array(String, Hash)+] Mutation GQL document and variables hash containing topic, URI, name, and optional parameters.
      # @api private
      #
      def build_creation_mutation
        mutation = <<~GRAPHQL
          mutation WebhookSubscriptionCreate($topic: WebhookSubscriptionTopic!, $subscription: WebhookSubscriptionInput!) {
            webhookSubscriptionCreate(topic: $topic, webhookSubscription: $subscription) {
              webhookSubscription {
                __typename
                id
                shopify_id: id
                topic
                filter
                uri
                fields: includeFields
                created_at: createdAt
              }
              userErrors {
                field
                message
              }
            }
          }
        GRAPHQL

        variables = {
          topic: graphql_topic_enum,
          subscription: {
            name: graphql_name,
            uri: shop&.webhook_callback_url(topic),
            includeFields: fields.presence,
            filter: filter.presence
          }.compact
        }

        [mutation, variables]
      end
    end
  end
end