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

# = XEngine Shopify
#
# The Shopify extension provides seamless integration between XEngine's behavior 
# trees and the Shopify Admin API. 
#
# It utilizes +Zeitwerk+ for lazy-loading and registers itself into the 
# {XEngine::Core::Registry} to participate in the engine's global boot sequence.
module XEngine
  module Shopify
    # :stopdoc:
    # Initialize Zeitwerk to handle constant loading within the XEngine namespace.
    @loader = Zeitwerk::Loader.for_gem_extension(XEngine)
    @loader.setup
    # :startdoc:
  end
end

# Register the extension with the Core Registry.
# This ensures XEngine.boot! can trigger the +on_register+ and +on_boot+ hooks.
XEngine::Core::Registry.register_extension(:shopify, XEngine::Shopify::Extension)