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
require "dry/monads"

module XEngine
  module Shopify
    module Nodes
      # = Refresh Access Token Node
      #
      # Low-level system node responsible for verifying and updating tenant Shopify access tokens.
      # If the shop token is still valid, returns early. Otherwise, performs a client credentials
      # OAuth handshake, persists changes, and clears cached API clients.
      #
      class RefreshAccessToken
        include Dry::Monads[:result]

        def self.call(...)
          new.call(...)
        end

        # Verifies and refreshes the shop access token.
        #
        # === Parameters
        # * +shop+ [+XEngine::Shopify::Shop+] - Active shop instance to check/refresh.
        #
        # === Returns
        # * +Dry::Monads::Result::Success(XEngine::Shopify::Shop)+
        # * +Dry::Monads::Result::Failure([Symbol, String])+
        #
        def call(shop:)
          return Failure([:bad_request, "Shop record must be present"]) if shop.blank?

          # 1. Skip network exchange if token is still valid
          return Success(shop) if shop.respond_to?(:access_token_valid?) && shop.access_token_valid?

          # 2. Extract credentials & perform OAuth handshake
          token_data = fetch_oauth_token(shop)
          return Failure(token_data) if token_data.is_a?(Array) # Returns error tuple on failure

          # 3. Assign attributes
          assign_token_attributes(shop, token_data[:token], token_data[:expiry])

          # 4. Persist updated token & expiry
          save_shop_credentials(shop)

          # 5. Clear cached HTTP/GraphQL client singletons
          shop.clear_api_clients! if shop.respond_to?(:clear_api_clients!)

          Success(shop)
        rescue StandardError => e
          Failure([:unauthorized, "Shopify token handshake failed [Shop ID: #{shop&.id}]: #{e.message}"])
        end

        private

        def fetch_oauth_token(shop)
          domain = shop.myshopify_domain.to_s.strip
          return [:unprocessable_entity, "Shop (ID: #{shop.id}) is missing myshopify_domain"] if domain.empty?

          credential    = shop.try(:credential)
          client_id     = (shop.try(:client_id) || credential&.client_id).to_s.strip
          client_secret = (shop.try(:client_secret) || credential&.client_secret).to_s.strip

          return [:unprocessable_entity, "Shop (ID: #{shop.id}) is missing client_id"] if client_id.empty?
          return [:unprocessable_entity, "Shop (ID: #{shop.id}) is missing client_secret"] if client_secret.empty?

          uri      = URI("https://#{domain}/admin/oauth/access_token")
          response = Net::HTTP.post_form(uri, {
            client_id:     client_id,
            client_secret: client_secret,
            grant_type:    "client_credentials"
          })

          unless response.is_a?(Net::HTTPSuccess)
            return [:unauthorized, "Shopify returned HTTP #{response.code}: #{response.body}"]
          end

          data  = JSON.parse(response.body)
          token = data["access_token"].to_s.strip

          return [:unauthorized, "Shopify API response missing access_token key"] if token.empty?

          expires_in = data["expires_in"].to_i
          { token: token, expiry: Time.current + expires_in }
        end

        def assign_token_attributes(shop, token, expiry)
          if shop.try(:credential).present?
            shop.credential.access_token = token
          elsif shop.respond_to?(:access_token=)
            shop.access_token = token
          end

          shop.api_expires = expiry if shop.respond_to?(:api_expires=)
        end

        def save_shop_credentials(shop)
          if shop.try(:credential).present?
            shop.credential.save!
          else
            shop.save!
          end
        end
      end
    end
  end
end