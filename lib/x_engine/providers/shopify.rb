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
Dry::System.register_provider_source(:shopify, group: :x_engine) do
  
  # Prepares the Shopify integration dependencies within the master container.
  #
  # Ensures prerequisite providers are initialized and mounts the primary config client.
  #
  # @return [void]
  prepare do
    target_container.start(:cli) if target_container.providers.key?(:cli)

    target_container.start(:web) if target_container.providers.key?(:web)

    require "x_engine/shopify/web/routes"

    # 1. Dynamically locate the root directory of this extension gem
      # (Points to your .../x_engine-shopify/lib path)
      extension_lib_dir = File.expand_path("../..", __dir__)

      # 2. Register this directory branch into the master application component scanner
      target_container.config.component_dirs.add(extension_lib_dir) do |dir|
        dir.namespaces.add "x_engine", key: nil
        dir.auto_register = true # Automatically populates and creates container keys
      end

    @shopify_client = XEngine::Shopify::Client.new
    register("shopify", @shopify_client)
  end

  # Activates the Shopify provider and wires subsystem dependencies.
  #
  # Synchronizes credentials with the underlying global context wrapper and appends
  # extension migration files safely onto the engine's active database instance registry.
  #
  # @return [void]
  start do
    logger = target_container["logger"]

    ::ShopifyAPI::Context.setup(
      api_key: @shopify_client.config.api_key,
      api_secret_key: @shopify_client.config.api_secret,
      scope: @shopify_client.config.scopes,
      is_embedded: true,
      is_private: false,
      api_version: @shopify_client.config.api_version
    )

    if target_container.providers.key?(:database)
      migration_path = File.expand_path("../shopify/db/migrate", __dir__)
      database_component = target_container["database"]
      
      if database_component.respond_to?(:register_migration_path)
        database_component.register_migration_path(migration_path)
      end
    end

    if logger
      logger.info("Shopify integration initialized for API version: #{::ShopifyAPI::Context.api_version}")
    end
  end
end