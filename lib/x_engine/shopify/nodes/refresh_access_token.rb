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

require 'net/http'
require 'uri'
require 'json'

module XEngine
  module Shopify
    module Nodes
      class RefreshAccessToken
        def call(myshopify_domain:, client_id:, client_secret:)
          uri = URI("https://#{myshopify_domain}/admin/oauth/access_token")
          
          # Net::HTTP.post_form handles the x-www-form-urlencoded header automatically
          response = Net::HTTP.post_form(uri, {
            client_id: client_id,
            client_secret: client_secret,
            grant_type: "client_credentials"
          })

          unless response.is_a?(Net::HTTPSuccess)
            raise "Shopify returned #{response.code}: #{response.body}"
          end

          data = JSON.parse(response.body)
          
          {
            access_token: data["access_token"],
            api_expires: Time.current + data["expires_in"].to_i.seconds
          }
        rescue => e
          raise "Handshake failed: #{e.message}"
        end
      end
    end
  end
end