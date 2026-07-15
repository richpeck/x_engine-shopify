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
##  RPECK 29/04/2026 - Configuration Provider Source
##  Exposes core setting structures natively to the engine container
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "shopify_api"

# = XEngine Shopify Provider Source
#
# Configures, registers, and orchestrates lifecycle operations for the Shopify 
# API integration within the +XEngine+ master container matrix.
#
Dry::System.register_provider_source(:shopify, group: :x_engine) do

  # Prepares the Shopify integration dependencies within the master container environment.
  #
  # This lifecycle phase ensures the local database migration paths are registered
  # with the engine's database provider and defines the factory for the main 
  # Shopify client component.
  #
  # @return [void]
  prepare do
    gem_root            = XEngine::Shopify::ROOT
    extension_lib_dir   = File.join(gem_root, "lib")

    # This invokes the :database provider's prepare and start steps
    target_container.prepare(:database)

    # 1. Register the structural migration path belonging to this extension
    if target_container.registered?(:database)
      migration_path = File.expand_path("x_engine/shopify/db/migrate", extension_lib_dir)
      target_container["database"].register_migration_path(migration_path)
    end

    # 2. Register the shopify client factory. 
    # The client is resolved lazily via XEngine::Shopify::Client, which is 
    # discovered and autoloaded by the engine's Zeitwerk instance.
    register("shopify", memoize: true) do
      XEngine::Shopify::Client.new
    end
  end

  # Activates the Shopify provider context matrix and binds running dependencies.
  #
  # Initializes the global +ShopifyAPI::Context+ structures by resolving the 
  # configuration from the registered +shopify+ client component.
  #
  # @return [void]
  start do
    client = target_container["shopify"]
    logger = target_container["logger"]

    ::ShopifyAPI::Context.setup(
      api_key:        client.config.api_key,
      api_secret_key: client.config.api_secret,
      scope:          client.config.scopes,
      is_embedded:    true,
      is_private:     false,
      api_version:    client.config.api_version
    )

    logger&.info("Shopify initialized for version: #{::ShopifyAPI::Context.api_version}")
  end
end