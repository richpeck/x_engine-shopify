# :stopdoc:
################################################################
################################################################
##   ________  ________  _______   ________  _________  _______           ________  ___  ___  ________  ________   
##  |\   ____\|\   __  \|\  ___ \ |\   __  \|\___   ___\\  ___ \         |\   ____\|\  \|\  \|\   __  \|\   __  \  
##  \ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \|___ \  \_\ \   __/|        \ \  \___|\ \  \\\  \ \  \|\  \ \  \|\  \ 
##   \ \  \    \ \   _  _\ \  \_|/_\ \   __  \   \ \  \ \ \  \_|/__       \ \_____  \ \   __  \ \  \\\  \ \   ____\
##    \ \  \____\ \  \\  \\ \  \_|\ \ \  \ \  \   \ \  \ \ \  \_|\ \       \|____|\  \ \  \ \  \ \  \\\  \ \  \___|
##     \ \_______\ \__\\ _\\ \_______\ \__\ \__\   \ \__\ \ \_______\        ____\_\  \ \__\ \__\ \_______\ \__\   
##      \|_______|\|__|\|__|\|_______|\|__|\|__|    \|__|  \|_______|       |\_________\|__|\|__|\|_______|\|__|   
##                                                                          \|_________|                           
##  --
##  RPECK 20/07/2026 - Create Shop
##  System which allows us to deploy various settings inside the app
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    module Nodes
      # = Shopify Create Shop Node
      #
      # Orchestrates the initial registration and multi-tenant setup of a Shopify Store within 
      # the platform. It handles opening a temporary communication channel with Shopify to fetch 
      # store administrative metadata, securely segregates access credentials into a standalone core 
      # security profile, and binds the newly synchronized storefront records in a single execution block.
      #
      class CreateShop < Dry::Operation

        # Resolves remote storefront details and registers the shop record locally.
        #
        # == Parameters:
        # [myshopify_domain]   The canonical immutable lookup domain (e.g., <tt>"example.myshopify.com"</tt>).
        # [access_token]       The primary cryptographic authentication wire token.
        # [api_expires]        Optional custom absolute timeout indicating token invalidation. Defaults to +nil+.
        # [client_id]          Optional application client identifier key. Defaults to +nil+.
        # [client_secret]      Optional application secret validation token. Defaults to +nil+.
        #
        # == Returns:
        # * <tt>Dry::Monads::Result::Success(XEngine::Shopify::Shop)</tt> containing the newly persisted shop instance.
        # * <tt>Dry::Monads::Result::Failure(String)</tt> containing the network or database error description message.
        #
        def call(myshopify_domain:, access_token:, api_expires: nil, client_id: nil, client_secret: nil)
          # Thread-isolated session context to grab store metadata details
          session = ShopifyAPI::Auth::Session.new(shop: myshopify_domain, access_token: access_token)
          client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
          
          # (GraphQL query logic execution to download shop fields goes here...)
          
          Shop.transaction do
            credential = XEngine::Core::Credential.create!(
              provider_type: "shopify",
              token_matrix: {
                access_token: access_token,
                client_id: client_id,
                client_secret: client_secret
              }.compact
            )

            shop = Shop.create!(
              credential: credential,
              myshopify_domain: myshopify_domain,
              api_expires: api_expires
              # ... mapped GraphQL payload variables (name, email, billing, etc)
            )
            
            Success(shop)
          end
        rescue => e
          Failure("Persistence error initializing shop: #{e.message}")
        end
      end
    end
  end
end