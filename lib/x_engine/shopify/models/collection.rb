# :stopdoc:
################################################################
################################################################
##   ________  ________  ___       ___       _______   ________ _________  ___  ________  ________      
##  |\   ____\|\   __  \|\  \     |\  \     |\  ___ \ |\   ____\\___   ___\\  \|\   __  \|\   ___  \    
##  \ \  \___|\ \  \|\  \ \  \    \ \  \    \ \   __/|\ \  \___\|___ \  \_\ \  \ \  \|\  \ \  \\ \  \   
##   \ \  \    \ \  \\\  \ \  \    \ \  \    \ \  \_|/_\ \  \       \ \  \ \ \  \ \  \\\  \ \  \\ \  \  
##    \ \  \____\ \  \\\  \ \  \____\ \  \____\ \  \_|\ \ \  \____   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ 
##     \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\  \ \__\ \ \__\ \_______\ \__\\ \__\
##      \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|   \|__|  \|__|\|_______|\|__| \|__|
##  --
##  RPECK 18/01/2024 - Collection object
##  Provides the base data-set for a collection
##  --
##  Ref: https://shopify.dev/docs/api/admin-graphql/2024-01/objects/Collection
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Collection Model
    #
    # Manages product assortments, custom groupings, and automated smart collection rules
    # synchronized directly down from the Shopify Admin API gateway layer.
    #
    # == Lifecycle Integration
    # This resource handles automatic handle synchronization utilizing the {XEngine::Shopify::HasHandle} 
    # concern, and exposes its standardized field selection footprint via {XEngine::Shopify::HasGraphQLRepresentation}.
    #
    class Collection < XEngine::Core::Model
      include XEngine::Shopify::HasHandle
      include XEngine::Shopify::HasGraphQLRepresentation

      # Automatically normalize the title attribute into the handle column
      has_handle :title

      # == GraphQL Layout Declarations
      # Binds endpoints, custom selection fragments, and default pipeline filters.
      expose_graphql single: :collection, multiple: :collections do
        <<~GRAPHQL
          __typename
          id 
          shopify_id: id
          title 
          handle 
          products_count: productsCount {
            count
          }
        GRAPHQL
      end

      # == Associations
      belongs_to :shop, class_name: "XEngine::Shopify::Shop", inverse_of: :collections

      has_and_belongs_to_many :products, -> { distinct }, class_name: "XEngine::Shopify::Product"
      has_many :variants, class_name: "XEngine::Shopify::ProductVariant", through: :products

      # == Validations
      validates :handle, :title, presence: true
    end
  end
end