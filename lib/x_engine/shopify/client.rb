# :stopdoc:
################################################################
################################################################
##   ________  ___  ___  ________  ________  ___  ________ ___    ___ 
##  |\   ____\|\  \|\  \|\   __  \|\   __  \|\  \|\  _____\\  \  /  /|
##  \ \  \___|\ \  \\\  \ \  \|\  \ \  \|\  \ \  \ \  \__/\ \  \/  / /
##   \ \_____  \ \   __  \ \  \\\  \ \   ____\ \  \ \   __\\ \    / / 
##    \|____|\  \ \  \ \  \ \  \\\  \ \  \___|\ \  \ \  \_| \/  /  /  
##      ____\_\  \ \__\ \__\ \_______\ \__\    \ \__\ \__\__/  / /    
##     |\_________\|__|\|__|\|_______|\|__|     \|__|\|__|\___/ /     
##     \|_________|                                      \|___|/      
##  --
##  RPECK 12/06/2026 - Client API Engine Wrapper
##  Manages Shopify configuration boundaries and credentials context
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "dry-configurable"

module XEngine
  module Shopify
    # = XEngine Shopify Client Orchestrator
    #
    # Encapsulates authentication context boundaries, version targets, interpolation settings,
    # and functional API scope definitions mapping application workflows onto the Shopify Partner ecosystem.
    #
    # == Container Registration
    # Rather than managing configuration globally via class-level constants, instances of this class 
    # are instantiated and managed directly within an IoC container (e.g. +XEngine::Application["shopify"]+).
    # This allows downstream parent applications to dynamically configure API settings via 
    # blocks directly exposed by the container interface.
    #
    # === Target Block Interface Example
    #
    #   XEngine::Application["shopify"].config do |config|
    #     config.api_key    = "shppa_xyz123..."
    #     config.api_secret = "shpss_abc456..."
    #     config.app_domain = "https://app.example.com"
    #     config.scopes     = ["read_products", "write_inventory", "read_orders"]
    #
    #     # Interpolation node transformations
    #     config.interpolation.strip_gids       = true
    #     config.interpolation.parse_timestamps = true
    #     config.interpolation.type_mappings["Product"] = "CustomProductModel"
    #     config.interpolation.custom_rules     = {
    #       sku: ->(val) { val.to_s.strip.upcase }
    #     }
    #   end
    #
    class Client
      # Including Dry::Configurable at the instance level isolates configurations 
      # uniquely to individual allocated Shopify manager objects inside the container.
      include Dry::Configurable

      # @!attribute [rw] api_key
      # The primary API Key generated via the Shopify Partner App Dashboard.
      # @return [String, nil]
      setting :api_key, default: ENV.fetch("XENGINE_SHOPIFY_API_KEY", "NO_KEY")

      # @!attribute [rw] api_secret
      # The primary Client Secret used to authenticate server-side OAuth handshakes.
      # @return [String, nil]
      setting :api_secret, default: ENV.fetch("XENGINE_SHOPIFY_API_SECRET", "NO_SECRET")

      # @!attribute [rw] app_domain
      # The fully qualified domain/host of this application (e.g. "https://app.yourdomain.com").
      # Used to construct OAuth redirect URIs, app proxies, and webhook callback endpoints.
      # @return [String, nil]
      setting :app_domain, default: ENV.fetch("XENGINE_SHOPIFY_APP_DOMAIN", nil)

      # @!attribute [rw] scopes
      # Authorized operational access metrics. Pass a comma-separated string 
      # via environment variables or assign an array directly.
      # @return [Array<String>]
      setting :scopes, 
              default: ENV.fetch("XENGINE_SHOPIFY_API_SCOPES", "read_products,read_orders"),
              constructor: ->(value) { value.is_a?(String) ? value.split(",").map(&:strip) : Array(value) }

      # @!attribute [rw] api_version
      # Targeted Shopify Web API stability version roadmap window.
      # Defaults to <tt>"2026-04"</tt>.
      # @return [String]
      setting :api_version, default: ENV.fetch("XENGINE_SHOPIFY_API_VERSION", "2026-04")

      # = Interpolation Configuration Boundaries
      # Configures key/value transformations executed by the +JSONInterpolator+ node.
      setting :interpolation do
        # @!attribute [rw] strip_gids
        # Automatically extracts numeric/string identifiers from raw GraphQL GIDs (e.g., "gid://shopify/Product/123" -> "123").
        # @return [Boolean]
        setting :strip_gids, default: true

        # @!attribute [rw] parse_timestamps
        # Converts ISO8601 string values matching UTC timestamps into native +Time+ objects.
        # @return [Boolean]
        setting :parse_timestamps, default: true

        # @!attribute [rw] type_mappings
        # Registry mapping incoming GraphQL +__typename+ identifiers to fully-qualified 
        # local domain or ActiveRecord model class strings.
        # @return [Hash{String => String}]
        setting :type_mappings, default: {
          "Product"        => "XEngine::Shopify::Product",
          "ProductVariant" => "XEngine::Shopify::ProductVariant",
          "MediaImage"     => "XEngine::Shopify::ProductImage",
          "Video"          => "XEngine::Shopify::ProductVideo"
        }

        # @!attribute [rw] field_mappings
        # Model-specific column alias dictionary. Maps GraphQL camelCase keys or 
        # parent line-item fields directly to target database attribute names.
        # @return [Hash{String => Hash{String => String}}]
        setting :field_mappings, default: {
          "XEngine::Shopify::Product" => {
            "legacyResourceId" => "legacy_id",
            "totalInventory"   => "total_inventory",
            "totalVariants"    => "total_variants",
            "productType"      => "product_type"
          },
          "XEngine::Shopify::ProductVariant" => {
            "legacyResourceId"  => "legacy_id",
            "inventoryQuantity" => "inventory_quantity",
            "parent_id"         => "product_id"
          },
          "XEngine::Shopify::ProductImage" => {
            "parent_id" => "product_id"
          }
        }

        # @!attribute [rw] fragment_unwrappers
        # List of callable Procs/lambdas executed sequentially to unroll nested GraphQL 
        # sub-fragments (e.g., media node objects or video sources) into flat attributes.
        # @return [Array<Proc>]
        setting :fragment_unwrappers, default: [
          lambda { |raw|
            if raw["image"].is_a?(Hash)
              img = raw.delete("image")
              raw["url"]    ||= img["url"]
              raw["height"] ||= img["height"]
              raw["width"]  ||= img["width"]
              raw["alt"]    ||= img["altText"]
            end
            raw
          },
          lambda { |raw|
            if raw["originalSource"].is_a?(Hash)
              src = raw.delete("originalSource")
              raw["url"]    ||= src["url"]
              raw["height"] ||= src["height"]
              raw["width"]  ||= src["width"]
            end
            raw
          }
        ]

        # @!attribute [rw] custom_rules
        # Hash mapping snakified key symbols to executable lambdas or callables for targeted field transformations.
        # @return [Hash{Symbol => Proc}]
        setting :custom_rules, default: {}, constructor: ->(rules) {
          return {} unless rules.is_a?(Hash)
          
          rules.each_with_object({}) do |(key, fn), acc|
            acc[key.to_s.underscore.to_sym] = fn
          end
        }
      end

      # Overrides the standard +config+ method signature to intercept and yield configuration blocks.
      # This provides an intuitive object DSL interface for parent initializers to quickly configure settings.
      #
      # === Yields
      # * [Dry::Configurable::Config] The active instance configuration state proxy object.
      #
      # @return [Dry::Configurable::Config] The configuration manager instance.
      def config
        if block_given?
          yield super
        else
          super
        end
      end

      # Validates whether the necessary authentication keys are physically present on disk or environment.
      #
      # @return [Boolean] True if both +api_key+ and +api_secret+ values are assigned and valid.
      def configured?
        config.api_key.present? && config.api_key != "NO_KEY" &&
          config.api_secret.present? && config.api_secret != "NO_SECRET"
      end

      # Convenience helper to form fully-qualified webhook callback URLs or endpoint URIs.
      #
      # @param path [String] Relative path for the callback target.
      # @return [String]
      def callback_url_for(path)
        base = config.app_domain.to_s.chomp("/")
        path = "/#{path.to_s.sub(%r{^/}, '')}"
        "#{base}#{path}"
      end

      # Creates an authenticated Shopify transient user or app session context.
      #
      # Used primarily inside functional nodes or background jobs to build localized 
      # API scopes dynamically using stored domain access tokens.
      #
      # @param shop [String] The target shop domain name (e.g., "example.myshopify.com").
      # @param token [String] The offline or online access token for the target shop.
      #
      # @return [ShopifyAPI::Auth::Session] An authenticated session boundary.
      def transient_session(shop:, token:)
        raise ArgumentError, "Shop domain required for transient session" if shop.blank?

        ::ShopifyAPI::Auth::Session.new(
          shop: shop,
          access_token: token
        )
      end
    end
  end
end