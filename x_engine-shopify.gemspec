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
# * Cryptographic HMAC context token verification for inbound webhooks via the official API wrapper.
# * State-aware, multi-tenant persistence layers tracking active, failing, or disabled subscriptions.
# * Optimized payload footprint scoping via advanced array column structural property targets.
# * Strict type-safe internal event validation powered by the +dry-rb+ data modeling ecosystem.
# * High-volume asynchronous GraphQL Bulk Operation runtime extraction and auditing pipelines.
# * Shopify-specific execution nodes compatible with the universal +XEngine::Core::Nodes+ layout API.
#
# == Engine Dependencies
# [shopify_api]     Platform authentication, access token mechanics, and webhook verification utilities.
# [dry-struct]      Type-safe layout validation rules for compiling immutable topic configurations.
# [dry-types]       Comprehensive constraint system managing string, array, and optional attribute bounds.
# [activerecord]    Relational mapping profiles connecting parent stores to nested operational objects.
# [zeitwerk]        Strict inflection-compliant directory tree autoloader matching engine patterns.
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
  
  # Type-safe object boundaries and attributes constraints for metadata management
  spec.add_dependency "dry-struct", "~> 1.6"
  spec.add_dependency "dry-types", "~> 1.7"

  # Persistence layer for Shopify Objects (Shops, Webhooks, Bulk Operations)
  spec.add_dependency "activerecord"
  
  # Autoloading for extension nodes and middleware
  spec.add_dependency "zeitwerk"

end
# :startdoc: