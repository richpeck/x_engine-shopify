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

module XEngine
  # == XEngine Shopify Extension
  #
  # Namespace for Shopify-specific functionality.
  module Shopify
    # = Shopify Extension Controller
    #
    # Manages the lifecycle and configuration of the Shopify stack.
    class Extension < Core::Extension

      # RPECK 01/05/2026 - Trigger the base class registration logic.
      # This automatically sets @migration_path to gem_root/db/migrate
      identifier :shopify
      
      # Returns the absolute path to the gem's root directory.
      # @return [Pathname]
      def self.root
        Pathname.new(File.expand_path('..', __dir__))
      end

      # ---
      # :section: Lifecycle Hooks
      # ---

      def self.on_register
        XEngine.configure do |config|
          config.setting :shopify do
            config.setting :api_key,    default: ENV.fetch("XENGINE_SHOPIFY_API_KEY",    nil)
            config.setting :api_secret, default: ENV.fetch("XENGINE_SHOPIFY_API_SECRET", nil)
            config.setting :scope,      default: ENV.fetch("XENGINE_SHOPIFY_SCOPE",      "read_products,read_orders")
          end
        end
      end

      def self.on_boot
        # Model and Node registration
      end
    end
  end
end

# ---
# :section: Autoloader Setup
# ---

# :stopdoc:
# Initialize Zeitwerk
loader = Zeitwerk::Loader.new
loader.tag = "x_engine-shopify"
loader.push_dir(File.expand_path("x_engine", __dir__)) 
loader.setup
# :startdoc: