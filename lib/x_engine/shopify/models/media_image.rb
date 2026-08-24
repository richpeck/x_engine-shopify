# :stopdoc:
################################################################
################################################################
##   _____ ______   _______   ________  ___  ________          ___  _____ ______   ________  ________  _______      
##  |\   _ \  _   \|\  ___ \ |\   ___ \|\  \|\   __  \        |\  \|\   _ \  _   \|\   __  \|\   ____\|\  ___ \     
##  \ \  \\\__\ \  \ \   __/|\ \  \_|\ \ \  \ \  \|\  \       \ \  \ \  \\\__\ \  \ \  \|\  \ \  \___|\ \   __/|    
##   \ \  \\|__| \  \ \  \_|/_\ \  \ \\ \ \  \ \   __  \       \ \  \ \  \\|__| \  \ \   __  \ \  \  __\ \  \_|/__  
##    \ \  \    \ \  \ \  \_|\ \ \  \_\\ \ \  \ \  \ \  \       \ \  \ \  \    \ \  \ \  \ \  \ \  \|\  \ \  \_|\ \ 
##     \ \__\    \ \__\ \_______\ \_______\ \__\ \__\ \__\       \ \__\ \__\    \ \__\ \__\ \__\ \_______\ \_______\
##      \|__|     \|__|\|_______|\|_______|\|__|\|__|\|__|        \|__|\|__|     \|__|\|__|\|__|\|_______|\|_______|
##  --
##  RPECK 20/08/2026 - Shopify Media Image Subclass
##  Dedicated STI model representing standard 2D graphical image assets
##  --
##  Ref: https://shopify.dev/docs/api/admin-graphql/latest/objects/MediaImage
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Media Image Model
    #
    # Single Table Inheritance (+STI+) concrete model representing 2D static graphical 
    # image assets synchronized from Shopify's GraphQL Admin API (+MediaImage+ fragment).
    #
    # Inherits core media attributes (such as +url+, +height+, +width+, +alt+, and +shop_id+) 
    # from {XEngine::Shopify::ProductMedia}.
    #
    # == GraphQL Payload Mapping
    #
    # Payloads originating from GraphQL +MediaImage+ nodes are flattened during stream 
    # interpolation via {XEngine::Shopify::MappingRepository} rules before being instantiated:
    #
    #   ... on MediaImage {
    #     id
    #     image {
    #       url
    #       height
    #       width
    #       altText
    #     }
    #   }
    #
    # @see XEngine::Shopify::ProductMedia
    #
    class MediaImage < ProductMedia
    end
  end
end