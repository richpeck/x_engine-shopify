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
      # Low-level execution node responsible for performing client credential OAuth exchange 
      # directly against Shopify's Admin API endpoint.
      #
      # == Responsibilities
      # * Validates presence of target domain and OAuth credentials.
      # * Sends HTTP POST request using +client_credentials+ grant type.
      # * Parses JSON token response and calculates absolute expiration time.
      #
      class RefreshAccessToken
        # Executes HTTP OAuth handshake against target Shopify domain.
        #
        # @param myshopify_domain [String] Fully qualified or myshopify domain (e.g., +"store.myshopify.com"+).
        # @param client_id [String] Shopify App Client ID / API Key.
        # @param client_secret [String] Shopify App Client Secret.
        #
        # @return [Hash{Symbol => String, ActiveSupport::TimeWithZone}]
        #   * +:access_token+ [String] Newly issued Admin API access token.
        #   * +:api_expires+ [Time] Calculated timestamp when token expires.
        #
        # @raise [ArgumentError] If any required parameter is missing or blank.
        # @raise [RuntimeError] If HTTP request fails or response payload is invalid.
        #
        def call(myshopify_domain:, client_id:, client_secret:)
          if myshopify_domain.to_s.strip.empty?
            raise ArgumentError, "myshopify_domain must be present"
          end

          if client_id.to_s.strip.empty?
            raise ArgumentError, "client_id is missing or blank for domain '#{myshopify_domain}'"
          end

          if client_secret.to_s.strip.empty?
            raise ArgumentError, "client_secret is missing or blank for domain '#{myshopify_domain}'"
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

          data = JSON.parse(response.body)

          unless data["access_token"].present?
            raise "Shopify API response missing expected access_token key"
          end

          {
            access_token: data["access_token"],
            api_expires:  Time.current + data["expires_in"].to_i.seconds
          }
        rescue StandardError => e
          raise "Handshake failed: #{e.message}"
        end
      end
    end
  end
end