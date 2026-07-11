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
    ROOT = File.expand_path("../..", __dir__).freeze

    # Configure the engine container to recognize this extension's directory.
    # This block executes when the framework application initializes.
    #
    # @param app [Dry::System::Container] The host framework container instance.
    # @return [void]
    def self.setup(app)
      app.config.component_dirs.add(File.join(ROOT, "lib")) do |dir|
        dir.namespaces.add "x_engine", key: nil
      end

      # Inflect API-specific acronyms for Zeitwerk compatibility
      app.config.autoloader.inflector.inflect(
        "graphql" => "GraphQL",
        "gid"     => "GID"
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