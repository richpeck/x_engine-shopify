# :stopdoc:
################################################################
################################################################
##   ________  _______   ________ ________  _______   ________  ___  ___          _________  ________  ___  __    _______   ________      
##  |\   __  \|\  ___ \ |\  _____\\   __  \|\  ___ \ |\   ____\|\  \|\  \        |\___   ___\\   __  \|\  \|\  \ |\  ___ \ |\   ___  \    
##  \ \  \|\  \ \   __/|\ \  \__/\ \  \|\  \ \   __/|\ \  \___|\ \  \\\  \       \|___ \  \_\ \  \|\  \ \  \/  /|\ \   __/|\ \  \\ \  \   
##   \ \   _  _\ \  \_|/_\ \   __\\ \   _  _\ \  \_|/_\ \_____  \ \   __  \           \ \  \ \ \  \\\  \ \   ___  \ \  \_|/_\ \  \\ \  \  
##    \ \  \\  \\ \  \_|\ \ \  \_| \ \  \\  \\ \  \_|\ \|____|\  \ \  \ \  \           \ \  \ \ \  \\\  \ \  \\ \  \ \  \_|\ \ \  \\ \  \ 
##     \ \__\\ _\\ \_______\ \__\   \ \__\\ _\\ \_______\____\_\  \ \__\ \__\           \ \__\ \ \_______\ \__\\ \__\ \_______\ \__\\ \__\
##      \|__|\|__|\|_______|\|__|    \|__|\|__|\|_______|\_________\|__|\|__|            \|__|  \|_______|\|__| \|__|\|_______|\|__| \|__|
##                                                      \|_________|                                                                      
##  --
##  RPECK 20/07/2026 - Refresh Access Token Node
##  Updates the API access token of stores
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module XEngine
  module Shopify
    module Nodes
      # = Refresh Access Token Node
      #
      # Low-level system node responsible for performing client credential OAuth exchange
      # directly against Shopify's Admin API endpoint for a given tenant shop.
      #
      # Assigns the newly issued token and calculated expiration timestamp directly to the shop model,
      # and returns a Hash containing the token metadata.
      #
      # Persistence (+save!+) is delegated to the invoking Operation boundary.
      #
      # == Usage Example
      #
      #   token_payload = XEngine::Shopify::Nodes::RefreshAccessToken.call(shop: shop)
      #   # => { access_token: "shpca_...", api_expires: 2026-08-05 11:28:48 UTC }
      #
      class RefreshAccessToken

        # Sugar method allowing direct class-level invocation.
        #
        # === Parameters
        # * +...+ - Arguments forwarded directly to {#call}.
        #
        # === Returns
        # * +Hash{Symbol => Object}+ - Hash containing +:access_token+ and +:api_expires+.
        #
        # @param (see #call)
        # @return (see #call)
        # @raise (see #call)
        #
        def self.call(...)
          new.call(...)
        end

        # Executes OAuth +client_credentials+ token handshake and sets attributes on the shop instance.
        #
        # === Parameters
        # * +shop+ [+XEngine::Shopify::Shop+] - Active shop instance to refresh token for.
        #
        # === Returns
        # * +Hash{Symbol => Object}+ - A Hash payload containing:
        #   * +:access_token+ [+String+] - The newly issued access token.
        #   * +:api_expires+ [+ActiveSupport::TimeWithZone+] - The calculated token expiration time.
        #
        # === Exceptions / Raises
        # * +ArgumentError+ - If shop record is missing, domain is blank, or client credentials are absent.
        # * +RuntimeError+ - If HTTP request fails, access token is missing from response payload, or handshake errors out.
        #
        # @param shop [XEngine::Shopify::Shop] Active shop model instance.
        # @return [Hash{Symbol => Object}] Hash containing +:access_token+ and +:api_expires+.
        # @raise [ArgumentError] If shop or required credentials are missing.
        # @raise [RuntimeError] If OAuth exchange fails upstream.
        #
        def call(shop:)
          raise ArgumentError, "shop record must be present" unless shop.present?

          myshopify_domain = shop.myshopify_domain.to_s.strip
          if myshopify_domain.empty?
            raise ArgumentError, "Shop (ID: #{shop.id}) is missing myshopify_domain"
          end

          credential    = shop.credential
          client_id     = (shop.try(:client_id) || credential&.client_id).to_s.strip
          client_secret = (shop.try(:client_secret) || credential&.client_secret).to_s.strip

          if client_id.empty?
            raise ArgumentError, "Shop (ID: #{shop.id}) is missing client_id"
          end

          if client_secret.empty?
            raise ArgumentError, "Shop (ID: #{shop.id}) is missing client_secret"
          end

          uri = URI("https://#{myshopify_domain}/admin/oauth/access_token")

          response = Net::HTTP.post_form(uri, {
            client_id:     client_id,
            client_secret: client_secret,
            grant_type:    "client_credentials"
          })

          unless response.is_a?(Net::HTTPSuccess)
            raise "Shopify returned #{response.code}: #{response.body}"
          end

          data  = JSON.parse(response.body)
          token = data["access_token"].to_s.strip

          if token.empty?
            raise "Shopify API response missing expected access_token key for shop ID #{shop.id}"
          end

          expires_in        = data["expires_in"].to_i
          calculated_expiry = Time.current + expires_in

          ## Attribute Assignment
          if credential.present?
            credential.access_token = token
          elsif shop.respond_to?(:access_token=)
            shop.access_token = token
          end

          shop.api_expires = calculated_expiry if shop.respond_to?(:api_expires=)

          {
            access_token: token,
            api_expires:  calculated_expiry
          }
        rescue StandardError => e
          raise "Handshake failed [Shop ID: #{shop&.id}]: #{e.message}"
        end

      end
    end
  end
end