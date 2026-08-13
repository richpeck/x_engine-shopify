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
    # = Shopify Shop Model
    #
    # Represents a Shopify store tenant within the XEngine ecosystem. This model uses the 
    # canonical +myshopify_domain+ as its primary immutable anchor for routing, while 
    # serving as the core cryptographic and multi-tenant parent scoping context for webhooks,
    # product media, transactions, and synchronous platform entity data pipelines.
    #
    # == Key Architectural Responsibilities
    # * *Polymorphic Credential Anchor:* Binds to a polymorphically-owned +XEngine::Core::Credential+ row handling encrypted access tokens.
    # * *API Client Factory:* Encapsulates thread-isolated session generation and memoized access to REST and GraphQL Admin API clients.
    # * *GraphQL Hydration Integration:* Declares field mappings consumed by +HasGraphQLRepresentation+ for automated remote metadata synchronization.
    # * *Resource Dispatcher:* Provides unified entry points (+resync+ / +resync!+) to pull and sync remote GraphQL resources for this store context.
    #
    class Shop < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Binds endpoints, custom selection fragments, and default pipeline filters
      # utilized during automated GraphQL metadata hydration sweeps.
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

      # Polymorphic single-credential association pointing to the shared secure authentication matrix.
      #
      # Destroying a shop cascades directly to purge its attached credential record from the core system.
      #
      # @return [XEngine::Core::Credential, nil]
      has_one :credential, 
              as: :owner, 
              class_name: "XEngine::Core::Credential", 
              dependent: :destroy

      # Permits nested assignment during single-pass atomic provisioning operations.
      accepts_nested_attributes_for :credential

      # Expose underlying credential readers and writers directly on the shop instance via proxy builder.
      delegate :access_token, :access_token=,
               :client_id, :client_id=,
               :client_secret, :client_secret=,
               to: :credential_or_build

      # Explicit mapping for irregular pluralizations to prevent unwanted ActiveSupport inflections.
      ASSOCIATION_CLASS_OVERRIDES = {
        product_media: "ProductMedia"
      }.freeze

      # Core domain associations scoped directly to this store instance.
      #
      # Generates dependent destroy associations for:
      # * +collections+ (+XEngine::Shopify::Collection+)
      # * +products+ (+XEngine::Shopify::Product+)
      # * +orders+ (+XEngine::Shopify::Order+)
      # * +bulk_operations+ (+XEngine::Shopify::BulkOperation+)
      # * +webhooks+ (+XEngine::Shopify::Webhook+)
      # * +product_media+ (+XEngine::Shopify::ProductMedia+)
      # * +metafields+ (+XEngine::Shopify::Metafield+)
      #
      # Destroying a shop cascades immediately to purge all attached records across these collections.
      #
      # @return [ActiveRecord::Associations::CollectionProxy]
      %i[
        collections
        products
        orders
        bulk_operations
        webhooks
        product_media
        metafields
      ].each do |assoc|
        target_class_name = ASSOCIATION_CLASS_OVERRIDES[assoc] || assoc.to_s.classify

        has_many assoc,
                 class_name: "XEngine::Shopify::#{target_class_name}",
                 foreign_key: :shop_id,
                 inverse_of: :shop,
                 dependent: :destroy
      end

      # ---
      # :section: Validations
      # ---

      validates :credential, presence: true
      validates :myshopify_domain, presence: true, uniqueness: true

      # ---
      # :section: Remote Synchronization Routing
      # ---

      # Dispatches a GraphQL synchronization request for the specified entity class and IDs
      # using this shop's authenticated GraphQL Admin API context.
      #
      # Any record failures during attribute assignment or persistence are swallowed or returned as
      # unpersisted instances depending on underlying implementation. Use {#resync!} if strict exception
      # propagation is required.
      #
      # @param resource_klass [Class, String, Symbol] A model class including +HasGraphQLRepresentation+ (e.g., +XEngine::Shopify::Product+)
      # @param ids [Array<String, Integer>, String, Integer] Single ID or array of IDs (raw numeric or GID)
      # @return [Array<XEngine::Core::Model>] Array of initialized or updated local records
      #
      # @example Resync a single product
      #   shop.resync(XEngine::Shopify::Product, "gid://shopify/Product/123456789")
      #
      # @example Resync multiple bulk operations by numeric ID
      #   shop.resync(XEngine::Shopify::BulkOperation, [101, 102])
      #
      def resync(resource_klass, ids)
        resync!(resource_klass, ids)
      rescue ActiveRecord::RecordInvalid, StandardError => e
        logger.error("[XEngine::Shopify::Shop#resync] Sync failed for #{resource_klass}: #{e.message}")
        []
      end

      # Dispatches a GraphQL synchronization request for the specified entity class and IDs
      # strictly raising exceptions if validation or GraphQL transport failures occur.
      #
      # @param resource_klass [Class, String, Symbol] A model class including +HasGraphQLRepresentation+ (e.g., +XEngine::Shopify::Product+)
      # @param ids [Array<String, Integer>, String, Integer] Single ID or array of IDs (raw numeric or GID)
      # @return [Array<XEngine::Core::Model>] Array of saved local records
      # @raise [ArgumentError] If the target resource class does not respond to GraphQL sync calls
      # @raise [ActiveRecord::RecordInvalid] If a record fails validation during save
      #
      def resync!(resource_klass, ids)
        target_ids = Array(ids).flatten.compact
        return [] if target_ids.empty?

        # Safely resolve constant if passed as String or Symbol
        klass = resource_klass.is_a?(Class) ? resource_klass : resource_klass.to_s.classify.constantize

        unless klass.respond_to?(:sync_nodes_from_shopify)
          raise ArgumentError, "#{klass.name} does not support Shopify syncing (missing HasGraphQLRepresentation)"
        end

        klass.sync_nodes_from_shopify(shop: self, ids: target_ids)
      end

      # ---
      # :section: API Client & Session Interface
      # ---

      # Instantiates a clean, thread-isolated API session block for outbound API execution calls
      # without binding credentials directly to a shared system global state.
      #
      # @return [ShopifyAPI::Auth::Session] Active API authorization session configured with store context.
      def to_shopify_session
        ShopifyAPI::Auth::Session.new(
          shop: myshopify_domain,
          access_token: access_token
        )
      end

      # Returns an instance-level GraphQL Admin API Client initialized for this specific store context.
      #
      # Client construction is memoized per model instance to prevent redundant session initializations
      # during iterative processing loops.
      #
      # @return [ShopifyAPI::Clients::Graphql::Admin] The initialized GraphQL Admin API client instance.
      def graphql_client
        @graphql_client ||= ShopifyAPI::Clients::Graphql::Admin.new(
          session: to_shopify_session
        )
      end

      # Returns an instance-level REST Admin API Client initialized for this specific store context.
      #
      # Client construction is memoized per model instance to prevent redundant session initializations
      # during iterative processing loops.
      #
      # @return [ShopifyAPI::Clients::Rest::Admin] The initialized REST Admin API client instance.
      def rest_client
        @rest_client ||= ShopifyAPI::Clients::Rest::Admin.new(
          session: to_shopify_session
        )
      end

      # Resets memoized API client instances forcing session re-initialization on subsequent calls
      # (e.g. after OAuth access token refreshes).
      #
      # @return [void]
      def clear_api_clients!
        @graphql_client = nil
        @rest_client    = nil
      end

      # ---
      # :section: Instance Helpers
      # ---

      # Evaluates whether the currently stored OAuth token is valid and safe for outbound requests,
      # enforcing a defensive 5-minute buffer window prior to formal API token expiration.
      #
      # @return [Boolean] +true+ if the token is present and unexpired; +false+ otherwise.
      def access_token_valid?
        access_token.present? && (
          api_expires.blank? || api_expires > 5.minutes.from_now
        )
      end

      # Helper profile evaluator confirming whether a targeted webhook topic is natively
      # compatible with this shop's currently locked API core version string context.
      #
      # @param topic [String] Lowercase wire format token (e.g., <tt>"products/update"</tt>).
      # @return [Boolean] +true+ if the topic is supported by the designated API version; +false+ otherwise.
      def webhook_compatible?(topic)
        XEngine::Shopify::Webhooks::Registry.compatible?(topic, api_version)
      end

      private

      # Defensive credential resolution proxy ensuring an associated credential instance exists
      # prior to setting nested properties directly.
      #
      # @return [XEngine::Core::Credential]
      def credential_or_build
        credential || build_credential
      end

    end
  end
end