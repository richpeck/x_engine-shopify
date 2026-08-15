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

require "shopify_api"
require "dry/monads"

module XEngine
  module Shopify
    module Nodes
      # = HMAC Verifier Node
      #
      # Node component responsible for validating incoming Shopify webhook authenticity.
      #
      # Delegates HMAC-SHA256 signature verification to +ShopifyAPI::Webhooks::Hmac.verify+,
      # comparing the unparsed HTTP request payload body against the incoming +X-Shopify-Hmac-SHA256+
      # HTTP header using the store tenant's client secret key.
      #
      # == Example Usage
      #
      #   node   = XEngine::Container["shopify.nodes.hmac_verifier"]
      #   result = node.call(
      #     raw_body: request_body_string,
      #     hmac_header: env["HTTP_X_SHOPIFY_HMAC_SHA256"],
      #     client_secret: shop.client_secret
      #   )
      #
      #   if result.success?
      #     puts "Signature verified"
      #   else
      #     code, message = result.failure
      #   end
      #
      class HMACVerifier
        include Dry::Monads[:result]

        # Verifies the HMAC signature of an incoming Shopify HTTP payload using ShopifyAPI SDK.
        #
        # === Parameters
        # * <tt>raw_body</tt> (+String+) -- Unparsed raw HTTP request payload body. *[Required]*
        # * <tt>hmac_header</tt> (+String+) -- Incoming +X-Shopify-Hmac-SHA256+ header value. *[Required]*
        # * <tt>client_secret</tt> (+String+) -- Tenant shop API secret key used for signing. *[Required]*
        #
        # === Returns
        # * +Dry::Monads::Result::Success(Boolean)+ -- Returns +true+ if signature is valid.
        # * +Dry::Monads::Result::Failure(Array)+ -- A two-element tuple containing:
        #   * <tt>:unauthorized</tt> (+Symbol+) -- Returned when inputs are missing or signature check fails.
        #   * <tt>message</tt> (+String+) -- Human-readable description of the verification failure.
        #
        def call(raw_body:, hmac_header:, client_secret:)
          return Failure([:unauthorized, "Missing raw HTTP request body for signature calculation"]) if raw_body.nil?
          return Failure([:unauthorized, "Missing HMAC signature header (X-Shopify-Hmac-SHA256)"]) if hmac_header.blank?
          return Failure([:unauthorized, "Missing client secret key for HMAC computation"]) if client_secret.blank?

          is_valid = ShopifyAPI::Webhooks::Hmac.verify(
            data: raw_body,
            hmac: hmac_header,
            secret: client_secret
          )

          if is_valid
            Success(true)
          else
            Failure([:unauthorized, "HMAC signature verification failed"])
          end
        rescue StandardError => e
          Failure([:unauthorized, "HMAC verification raised exception: #{e.message}"])
        end
      end
    end
  end
end