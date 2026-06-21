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

require "zeitwerk"
require "dry/system"

# = XEngine Sidekiq Extension
#
# Integrates Sidekiq background job processing into the XEngine ecosystem.
# Coordinates internal autoloader path structures and configures distributed 
# component provider group matrices.
#
module XEngine
  module Shopify
    # Dedicated, high-performance Zeitwerk loader for the Sidekiq gem extension layer.
    # 
    # @return [Zeitwerk::Loader] The active tracking loader instance.
    #
    LOADER = Zeitwerk::Loader.for_gem_extension(XEngine).tap do |loader|
      # Enforce uppercase acronym conversion rules for terminal CLI boundaries
      loader.inflector.inflect("graphql" => "graphQL")

      # Collapses the internal layout boundaries to expose models and concerns 
      # directly under the top-level extension module namespace.
      loader.collapse("#{__dir__}/shopify/models")
      
      # CRITICAL: Bypasses the providers folder so Zeitwerk doesn't mistake 
      # its contents for continuous Ruby constant namespaces.
      loader.ignore("#{__dir__}/providers")
      
      # Commit changes and establish the tracking system maps
      loader.setup
    end
  end
end

# --- SYSTEM PROVIDER GROUP MATRIX CONFIGURATION ---
# Inform the container system that this extension group's external providers are 
# located inside our isolated local +./providers+ folder.
#
# This implicitly maps the file located at <tt>lib/x_engine/providers/sidekiq.rb</tt> 
# containing the central +Dry::System.register_provider_source+ configuration schemas.
#
Dry::System.register_provider_sources(File.join(__dir__, "providers"))

# --- AUTOMATIC APPLICATION ADAPTER BINDING ---
# Automatically mounts the background processor provider component onto the running 
# framework master container tree if it has been evaluated into active process memory.
#
XEngine::Application.register_provider(:shopify, from: :x_engine) if defined?(XEngine::Application)