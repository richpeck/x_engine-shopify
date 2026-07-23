# :stopdoc:
################################################################
################################################################
##   ________  ___  ___  ________  ________  ________      
##  |\   ____\|\  \|\  \|\   __  \|\   __  \|\   ____\     
##  \ \  \___|\ \  \\\  \ \  \|\  \ \  \|\  \ \  \___|_    
##   \ \_____  \ \   __  \ \  \\\  \ \   ____\ \_____  \   
##    \|____|\  \ \  \ \  \ \  \\\  \ \  \___|\|____|\  \  
##      ____\_\  \ \__\ \__\ \_______\ \__\     ____\_\  \ 
##     |\_________\|__|\|__|\|_______|\|__|    |\_________\
##     \|_________|                            \|_________|
## --
##  RPECK 20/07/2026 - Shop
##  Model used to manage the shop objects inside the Shopify context
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Shop
    #
    # Represents a Shopify Store tenant within the XEngine ecosystem. This model uses the 
    # "handle" (subdomain) as its primary public identity for clean, readable routing, while 
    # serving as the core cryptographic and multi-tenant parent scoping anchor for webhooks,
    # transactions, and synchronous platform entity data pipelines.
    #
    class Shop < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Binds endpoints, custom selection fragments, and default pipeline filters.
      expose_graphql single: :shop do
        <<~GRAPHQL
          __typename
          id
          name
          email
          url
          currencyCode
          myshopify_domain: myshopifyDomain
          created_at:       createdAt
        GRAPHQL
      end

      # ---
      # :section: Associations
      # ---

      # Points directly to the shared secure authentication matrix table inside the Core gem block.
      belongs_to :credential,
                 class_name: "XEngine::Core::Credential",
                 foreign_key: :credential_id,
                 inverse_of: false

      # State-aware webhook endpoint subscriptions registered for this specific storefront.
      # Destroying a shop cascades immediately to purge tracking matrices, mitigating orphan records.
      has_many :webhooks,
               class_name: "XEngine::Shopify::Webhook",
               foreign_key: :shop_id,
               inverse_of: :shop,
               dependent: :destroy

      # Consolidated collection of rich asset components (images, videos, and 3D models)
      # tied directly to this store instance. Orphan records are automatically purged on destruction.
      has_many :product_media,
               class_name: "XEngine::Shopify::ProductMedia",
               foreign_key: :shop_id,
               inverse_of: :shop,
               dependent: :destroy

      # ---
      # :section: Validations
      # ---

      validates :credential, presence: true
      validates :myshopify_domain, presence: true, uniqueness: true
      
      # Defensive security guard: Assert that the associated credential row is explicitly 
      # scoped for Shopify operations rather than a mislinked mail server setup.
      validate :validate_provider_integrity, if: :credential

      # ---
      # :section: Cryptographic Key Resolvers
      # ---

      # Extracts the access token / API key out of the secure core JSON matrix.
      # @return [String, nil]
      def access_token
        credential&.get(:access_token) || credential&.get(:api_key)
      end

      # Extracts the application public client identifier key out of the secure core JSON matrix.
      # @return [String, nil]
      def client_key
        credential&.get(:api_key) || credential&.get(:client_key)
      end

      # Extracts the application cryptographic secret validation token out of the secure core JSON matrix.
      # @return [String, nil]
      def client_secret
        credential&.get(:api_secret) || credential&.get(:client_secret)
      end

      # ---
      # :section: API Client & Session Interface
      # ---

      # Instantiates a clean, thread-isolated API session block for outbound node execution calls
      # without binding credentials directly to a shared system global state.
      #
      # @return [ShopifyAPI::Auth::Session]
      def to_shopify_session
        ShopifyAPI::Auth::Session.new(
          shop: myshopify_domain,
          access_token: access_token
        )
      end

      # Returns an instance-level GraphQL Admin Client initialized for this specific store.
      # Memoized per model instance to prevent redundant client construction during execution loops.
      #
      # @return [ShopifyAPI::Clients::Graphql::Admin]
      def graphql_client
        @graphql_client ||= ShopifyAPI::Clients::Graphql::Admin.new(
          session: to_shopify_session
        )
      end

      # Returns an instance-level REST Admin Client initialized for this specific store.
      # Memoized per model instance to prevent redundant client construction during execution loops.
      #
      # @return [ShopifyAPI::Clients::Rest::Admin]
      def rest_client
        @rest_client ||= ShopifyAPI::Clients::Rest::Admin.new(
          session: to_shopify_session
        )
      end

      # ---
      # :section: Instance Methods
      # ---

      # Evaluates whether the currently stored OAuth token is valid and safe for outbound requests,
      # ensuring a defensive 5-minute buffer window prior to formal API expiration.
      #
      # @return [Boolean]
      def access_token_valid?
        access_token.present? && (
          api_expires.blank? || api_expires > 5.minutes.from_now
        )
      end

      # Helper profile evaluator confirming whether a targeted webhook topic is natively
      # compatible with this shop's currently locked API core version string context.
      #
      # @param topic [String] Lowercase wire format token (e.g. "products/update")
      # @return [Boolean]
      def webhook_compatible?(topic)
        XEngine::Shopify::Webhooks::Registry.compatible?(topic, api_version)
      end

      private

      # Defensive multi-tenant mapping safety check
      # @return [void]
      def validate_provider_integrity
        return if credential.provider_type == "shopify"

        errors.add(:credential_id, "must link directly to an explicit 'shopify' provider type token container profile.")
      end

    end
  end
end