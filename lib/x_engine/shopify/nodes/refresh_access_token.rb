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
##  RPECK 20/07/2026 - Refresh Access Token
##  Updates the API access token of stores
################################################################
################################################################
# :startdoc:

module XEngine
  module Shopify
    module Nodes
      # = Shopify Access Token Refresh Node
      #
      # Handles outbound OAuth client credential handshakes to request, rotate, and
      # refresh short-lived background API tokens from Shopify server nodes.
      #
      class RefreshAccessToken < Dry::Operation

        # Executes the OAuth handshake request against the targeted Shopify domain storefront.
        #
        # == Parameters:
        # [myshopify_domain]   The permanent immutable canonical look-up domain (e.g., <tt>"example.myshopify.com"</tt>).
        # [client_id]          The primary application client public identifier key.
        # [client_secret]      The application cryptographic secret validation token.
        #
        # == Returns:
        # * <tt>Dry::Monads::Result::Success(Hash)</tt> containing +:access_token+ and absolute +:api_expires+ timestamp.
        # * <tt>Dry::Monads::Result::Failure(String)</tt> explaining credential errors, handshake failures, or network issues.
        #
        def call(myshopify_domain:, client_id:, client_secret:)
          return Failure("Missing core credentials for token handshake.") if client_id.blank? || client_secret.blank?

          response = Net::HTTP.post(
            URI("https://#{myshopify_domain}/admin/oauth/access_token"),
            {
              client_id: client_id,
              client_secret: client_secret,
              grant_type: "client_credentials"
            }.to_json,
            { "Content-Type" => "application/json" }
          )

          return Failure("Shopify Handshake Error: #{response.code}") unless response.is_a?(Net::HTTPSuccess)

          body = JSON.parse(response.body)
          Success({
            access_token: body.fetch("access_token"),
            api_expires: Time.current + body.fetch("expires_in").to_i.seconds
          })
        rescue => e
          Failure("Network exception during token rotation: #{e.message}")
        end
      end
    end
  end
end