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
  # === Lifecycle Operations
  # 1. Resolves and registers the local database migration directory directly to the orchestrator layer.
  # 2. Injects the extension gem's library directory paths into the main application's component scanner.
  # 3. Aliases the automatically discovered client component instance to the short +shopify+ key slot.
  #
  # @return [void]
  prepare do
    extension_lib_dir = File.expand_path("../..", __dir__)

    # 1. Register the structural migration path belonging to this extension
    if target_container.providers.key?(:database)
      migration_path = File.expand_path("x_engine/shopify/db/migrate", extension_lib_dir)
      target_container["database"].register_migration_path(migration_path)
    end

    # 2. Let dry-system completely replace Zeitwerk. It will handle the directory 
    # monitoring and dynamic file resolution by itself.
    target_container.config.component_dirs.add(extension_lib_dir) do |dir|
      dir.namespaces.add "x_engine", key: nil
      dir.auto_register = true
    end

    # Safely look up the component via the container keys now that the directory is added.
    register("shopify") { target_container["x_engine.shopify.client"] }
  end

  # Activates the Shopify provider context matrix and binds running dependencies.
  #
  # Resolves the configured container credentials and initializes the underlying global 
  # +ShopifyAPI::Context+ structures using the active client configurations.
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