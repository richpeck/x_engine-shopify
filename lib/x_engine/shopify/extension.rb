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

require "shopify_api"

module XEngine
  module Shopify
    # = Shopify Extension Controller
    #
    # This class manages the lifecycle and configuration schema for the Shopify stack.
    # It inherits from {XEngine::Core::Extension} to gain standardized path
    # and identifier management.
    #
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
      # [api_version] The default locked baseline API target version (Default: '2026-04')
      def self.on_register
        XEngine::Core::Configuration.setting :shopify do
          setting :api_version, default: ENV.fetch("XENGINE_SHOPIFY_API_VERSION", "2026-04")
        end
      end

      # Phase 2: Boot
      #
      # This hook is called by +XEngine.boot!+ after the database is connected.
      # It establishes a dynamic-ready neutral fallback context inside the official gem.
      # Because keys and secrets live securely inside individual core credential models,
      # this boilerplate prevents boot crashes while isolating client tenancies.
      #
      def self.on_boot
        # Extract the compiled settings block from Core configuration
        config = XEngine::Core::Configuration.shopify

        # Initialize the baseline Shopify API Context block.
        # Passing placeholders satisfies the gem wrapper initialization rules while 
        # protecting multi-app workflows from thread-safety credential leaks.
        ShopifyAPI::Context.setup(
          api_key:       "DYNAMIC_TENANT_ISOLATION_ACTIVE",
          api_secret:    "DYNAMIC_TENANT_ISOLATION_ACTIVE",
          scope:         "read_products", # Handled dynamically per-session token loop
          api_version:   config.api_version,
          is_embedded:   true,
          is_private:    false
        )
      rescue => e
        # Prevent engine initializers from silently failing on missing context arrays
        warn "[XEngine::Shopify] Failed to initialize neutral Shopify API Context: #{e.message}"
      end
    end
  end
end
# :startdoc: