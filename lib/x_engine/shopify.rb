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
##  RPECK 22/04/2026 - XEngine Shopify
##  Used to provide the means to enhance the underlying system/engine so that the system can be stacked atop it
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "dry/system"

# = XEngine Framework Extension Suite
#
# Base namespace governing plugin layers and specialized component providers 
# stacked atop the core runtime platform.
#
module XEngine

  # = Shopify Extension Layer
  #
  # Integrates Shopify API interactions, webhook ingress routers, and 
  # synchronized e-commerce object mappings seamlessly into the core 
  # system graph.
  #
  module Shopify

    # Absolute path to the gem's root directory (c:/Dev/Apps/x_engine-shopify)
    # @return [String]
    ROOT = File.expand_path("../..", __dir__).freeze

    # Defines the localized database table name prefix for models nested inside
    # the +XEngine::Shopify+ namespace.
    #
    # === ActiveRecord Namespace Inheritance
    # When ActiveRecord resolves table names for nested models (e.g. +XEngine::Shopify::Shop+),
    # it traverses +module_parents+ from root to leaf (+[XEngine, XEngine::Shopify]+) and 
    # concatenates all returned +table_name_prefix+ strings in sequence.
    #
    # * Parent (+XEngine.table_name_prefix+): +"xe_"+
    # * Child (+XEngine::Shopify.table_name_prefix+): +"shopify_"+
    # * Combined Prefix: +"xe_shopify_"+
    # * Target Table Name: +"xe_shopify_shops"+
    #
    # Do NOT include parent prefixes (e.g. +"xe_"+) inside this method string,
    # as ActiveRecord will prepend parent module prefixes automatically during hierarchy traversal.
    #
    # === Returns
    # * +String+ - The module-specific suffix prefix ("shopify_").
    #
    def self.table_name_prefix
      "shopify_"
    end

    # Configures the engine container to recognize this extension's directory,
    # passes extension-specific acronym rules down to the global accumulation matrix,
    # and optimizes the autoloader layout.
    #
    # @param app [Dry::System::Container] The host framework container instance.
    # @return [void]
    #
    # === Example
    #   XEngine::Shopify.setup(XEngine::Application)
    #
    def self.setup(app)
      # Pushes extension-specific acronyms into the centralized application matrix.
      # These will be compiled safely via Dry::Inflector right before configuration.
      app.autoloader.inflector.inflect(
        "graphql"                    => "GraphQL",
        "gid"                        => "GID",
        "has_graphql_representation" => "HasGraphQLRepresentation"
      )

      # Register the various directories required for components
      app.config.component_dirs.add File.join(ROOT, "lib") do |dir|
        dir.namespaces.add "x_engine", key: nil
        dir.auto_register = ->(component) { component.identifier.start_with?("shopify.nodes") }
      end

      # Register the extension lib directory for component scanning
      app.autoloader.push_dir(
        File.join(ROOT, "lib")
      )

      # Exclude internal provider definitions from Zeitwerk's autoloader
      app.autoloader.ignore(
        File.join(ROOT, "lib/x_engine/providers"),
        File.join(ROOT, "lib/x_engine/shopify/version.rb"),
        File.join(ROOT, "lib/x_engine/shopify/db")
      )

      # Collapse nested data mapping models into flat namespaces
      app.autoloader.collapse(
        File.join(ROOT, "lib/x_engine/shopify/models"),
        File.join(ROOT, "lib/x_engine/shopify/models/concerns")
      )
    end
  end
end

# --- SYSTEM PROVIDER GROUP MATRIX CONFIGURATION ---
# Inform the container system that this extension group's external providers are 
# located inside our isolated local +./providers+ folder.
Dry::System.register_provider_sources(File.join(__dir__, "providers"))

# --- AUTOMATIC APPLICATION ADAPTER BINDING ---
# Bind the provider to the framework application after the environment is ready.
if defined?(XEngine::Application)
  XEngine::Shopify.setup(XEngine::Application)
  XEngine::Application.register_provider(:shopify, from: :x_engine)
end