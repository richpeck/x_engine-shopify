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
# == Lifecycle Stages
#
# This provider breaks execution down into two deterministic framework gates:
#
# 1. **Prepare:** Allocates the instance-level +Dry::Configurable+ {XEngine::Shopify::Client} 
#    dependency, satisfies immediate CLI runtime maps, and registers the client into the container room.
# 2. **Start:** Finalizes credentials context for the underlying +ShopifyAPI::Context+ 
#    using the resolved configuration settings, dynamically injects the engine's data migration 
#    paths onto the platform's active database component layer, and outputs system telemetry.
#
Dry::System.register_provider_source(:shopify, group: :x_engine) do
  
  # Prepares the Shopify integration dependencies within the master container.
  #
  # Ensures prerequisite providers are initialized before instantiating and 
  # registering the centralized configuration client instance.
  #
  # @return [void]
  prepare do
    # Force the core CLI component provider to finish initializing its internal maps
    target_container.start(:cli) if target_container.providers.key?(:cli)

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

    # Initialize standard Shopify API dynamic runtime context configurations 
    # out of the dry-configurable client instance settings map.
    ::ShopifyAPI::Context.setup(
      api_key: @shopify_client.config.api_key,
      api_secret_key: @shopify_client.config.api_secret,
      scope: @shopify_client.config.scopes,
      is_embedded: true,
      is_private: false,
      api_version: @shopify_client.config.api_version
    )

    # == Dynamic Extension Migration Injection
    # Inspects the master container for an operational database component. If located,
    # the engine expands its local schema definitions and pushes them directly onto the
    # provider's target search path stack.
    if target_container.providers.key?(:database)
      migration_path = File.expand_path("../shopify/db/migrate", __dir__)
      database_component = target_container["database"]
      
      if database_component.respond_to?(:register_migration_path)
        database_component.register_migration_path(migration_path)
      end
    end

    # == System Telemetry Output
    if logger
      logger.info("Shopify integration initialized for API version: #{::ShopifyAPI::Context.api_version}")
    end
  end
end