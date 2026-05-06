# :stopdoc:
################################################################
################################################################
##   _______      ___    ___ _________  _______   ________   ________  ___  ________  ________      
##  |\  ___ \    |\  \  /  /|\___   ___\\  ___ \ |\   ___  \|\   ____\|\  \|\   __  \|\   ___  \    
##  \ \   __/|   \ \  \/  / ||___ \  \_\ \   __/|\ \  \\ \  \ \  \___|\ \  \ \  \|\  \ \  \\ \  \   
##   \ \  \_|/__  \ \    / /     \ \  \ \ \  \_|/_\ \  \\ \  \ \_____  \ \  \ \  \\\  \ \  \\ \  \  
##    \ \  \_|\ \  /     \/       \ \  \ \ \  \_|\ \ \  \\ \  \|____|\  \ \  \ \  \\\  \ \  \\ \  \ 
##     \ \_______\/  /\   \        \ \__\ \ \_______\ \__\\ \__\____\_\  \ \__\ \_______\ \__\\ \__\
##      \|_______/__/ /\ __\        \|__|  \|_______|\|__| \|__|\_________\|__|\|_______|\|__| \|__|
##               |__|/ \|__|                                   \|_________|                         
##  --
##  RPECK 22/04/2026 - XEngine Shopify Extension
##  Class providing the means to manage how the Shopify extension interfaces with the XEngine core
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Extension Controller
    #
    # This class manages the lifecycle and configuration schema for the Shopify stack.
    # It inherits from {XEngine::Core::Extension} to gain standardized path
    # and identifier management.
    class Extension < Core::Extension

      # Trigger the base class registration logic.
      # This identifies the extension as +:shopify+ in the registry.
      identifier :shopify
      
      # Returns the absolute path to the gem's root directory.
      # Used by the Core to locate migrations and assets.
      # @return [Pathname]
      def self.root
        Pathname.new(File.expand_path('../../..', __dir__))
      end

      # ---
      # :section: Lifecycle Hooks
      # ---

      # Phase 1: Registration
      #
      # This hook is called by +XEngine.boot!+ before the database connects.
      # It injects the Shopify-specific configuration schema into 
      # {XEngine::Core::Configuration}.
      #
      # === Config Options:
      # [api_key]    The Shopify App API Key (Default: ENV['XENGINE_SHOPIFY_API_KEY'])
      # [api_secret] The Shopify App API Secret (Default: ENV['XENGINE_SHOPIFY_API_SECRET'])
      # [scope]      The required OAuth scopes (Default: 'read_products,read_orders')
      def self.on_register
        XEngine::Core::Configuration.setting :shopify do
          setting :api_key,    default: ENV.fetch("XENGINE_SHOPIFY_API_KEY",    nil)
          setting :api_secret, default: ENV.fetch("XENGINE_SHOPIFY_API_SECRET", nil)
          setting :scope,      default: ENV.fetch("XENGINE_SHOPIFY_SCOPE",      "read_products,read_orders")
        end
      end

      # Phase 2: Boot
      #
      # This hook is called by +XEngine.boot!+ after the database is connected.
      # Use this to register Nodes and Models into the {XEngine::Core::Registry}.
      def self.on_boot
        # Implementation: Register logic nodes for the behavior tree
        # XEngine::Core::Registry.register_node("shopify.get_order") { ... }
      end
    end
  end
end