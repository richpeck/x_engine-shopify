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
##  RPECK 23/04/2026 - XEngine Shopify Gemspec
##  Integrates with Shopify API to provide the means to manage data from the platform (includes nodes, auth, middleware and models)
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require_relative "lib/x_engine/shopify/version"

# = XEngine Shopify Extension
#
# This extension provides the core integration between XEngine and the Shopify platform.
# It implements a "Zero Trust" node architecture, ensuring that all data managed
# via the Shopify API is validated and authenticated via a dedicated middleware stack.
#
# == Features
# * HMAC verification for inbound webhooks.
# * Shopify-specific nodes for the Workflow Engine.
# * +ActiveRecord+ models for persisting Shopify data (Orders, Products, etc.).
Gem::Specification.new do |spec|

  # == Metadata
  spec.name     = "x_engine-shopify"
  spec.version  = XEngine::Shopify::VERSION
  spec.license  = "MIT"
  spec.authors  = ["Richard Peck"]
  spec.email    = ["support@pcfixes.com"]
  spec.homepage = "https://www.pcfixes.com"
  spec.summary  = "Shopify extension for XEngine."

  # :stopdoc:
  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]
  # :startdoc:

  # == Dependencies
  
  # The official Shopify library for API and Session management
  spec.add_dependency 'shopify_api', '~> 16.2'
  
  # Persistence layer for Shopify Objects (Orders, Customers)
  spec.add_dependency "activerecord"
  
  # Autoloading for extension nodes and middleware
  spec.add_dependency "zeitwerk"

end