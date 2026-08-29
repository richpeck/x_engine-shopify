# :stopdoc:
################################################################
################################################################
##   ___  ___  _____ ______   ________  ________     
##  |\  \|\  \|\   _ \  _   \|\   __  \|\   ____\    
##  \ \  \\\  \ \  \\\__\ \  \ \  \|\  \ \  \___|    
##   \ \   __  \ \  \\|__| \  \ \   __  \ \  \       
##    \ \  \ \  \ \  \    \ \  \ \  \ \  \ \  \____  
##     \ \__\ \__\ \__\    \ \__\ \__\ \__\ \_______\
##      \|__|\|__|\|__|     \|__|\|__|\|__|\|_______|
## --
##  RPECK 03/08/2026 - HMAC Verifier Node
##  Delegates Shopify HMAC-SHA256 signature verification to ShopifyAPI::Webhooks::Hmac
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "dry/monads"
require "openssl"
require "base64"
require "active_support/security_utils"

module XEngine
  module Shopify
    module Nodes
      # = Webhook HMAC Verification Gateway Node
      #
      # Self-contained node component responsible for tenant-aware webhook authentication.
      # Resolves store context (<tt>X-Shopify-Shop-Domain</tt>) and verifies the inbound
      # HMAC-SHA256 signature directly using constant-time comparison.
      #
      class HMACVerifier
        include Dry::Monads[:result]

        # Evaluates payload HMAC authenticity directly.
        #
        # === Parameters
        # * <tt>env</tt> (+Hash+) -- Incoming Rack environment headers. *[Required]*
        # * <tt>body</tt> (+String+) -- Raw unparsed HTTP request payload body. Defaults to empty string. *[Optional]*
        #
        # === Returns
        # * +Dry::Monads::Result::Success(Hash)+ -- Verification outcome
        # * +Dry::Monads::Result::Failure(Array)+ -- [:unauthorized, message]
        #
        def call(env:, body: "", **)
          rack_env = env.transform_keys(&:upcase)
          shop_domain = rack_env["HTTP_X_SHOPIFY_SHOP_DOMAIN"]
          hmac_header = rack_env["HTTP_X_SHOPIFY_HMAC_SHA256"]

          # 1. Resolve tenant shop credentials
          shop = find_shop(shop_domain)
          client_secret = shop&.client_secret.presence || ENV["SHOPIFY_CLIENT_SECRET"]

          # 2. Bypass signature enforcement if secret is unconfigured (dev/test environments)
          if client_secret.blank?
            return Success(skipped: true, reason: "No client secret configured for domain: #{shop_domain || 'unknown'}")
          end

          # 3. Guard against missing HMAC header
          if hmac_header.blank?
            return Failure([:unauthorized, "Missing HTTP_X_SHOPIFY_HMAC_SHA256 header"])
          end

          # 4. Perform direct HMAC-SHA256 calculation
          calculated_hmac = Base64.strict_encode64(
            OpenSSL::HMAC.digest(
              OpenSSL::Digest.new("sha256"),
              client_secret,
              body.to_s
            )
          )

          # 5. Constant-time secure comparison
          if ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
            Success(verified: true, shop: shop)
          else
            Failure([:unauthorized, "HMAC signature mismatch"])
          end
        rescue StandardError => e
          Failure([:unauthorized, "Verification error: #{e.message}"])
        end

        private

        def find_shop(domain)
          return nil if domain.blank?

          shop_class = defined?(Shopify::Shop) ? Shopify::Shop : XInventory::Models::Shop
          shop_class.find_by(myshopify_domain: domain) || shop_class.find_by(domain: domain)
        rescue StandardError
          nil
        end
      end
    end
  end
end