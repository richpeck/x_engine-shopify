# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  ________  ___  ___  ________ _________        ________  ________  ___       ___       _______   ________ _________  ___  ________  ________      
##  |\   __  \|\   __  \|\   __  \|\   ___ \|\  \|\  \|\   ____\\___   ___\     |\   ____\|\   __  \|\  \     |\  \     |\  ___ \ |\   ____\\___   ___\\  \|\   __  \|\   ___  \    
##  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \___\|___ \  \_|     \ \  \___|\ \  \|\  \ \  \    \ \  \    \ \   __/|\ \  \___\|___ \  \_\ \  \ \  \|\  \ \  \\ \  \   
##   \ \   ____\ \   _  _\ \  \\\  \ \  \ \\ \ \  \\\  \ \  \       \ \  \       \ \  \    \ \  \\\  \ \  \    \ \  \    \ \  \_|/_\ \  \       \ \  \ \ \  \ \  \\\  \ \  \\ \  \  
##    \ \  \___|\ \  \\  \\ \  \\\  \ \  \_\\ \ \  \\\  \ \  \____   \ \  \       \ \  \____\ \  \\\  \ \  \____\ \  \____\ \  \_|\ \ \  \____   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ 
##     \ \__\    \ \__\\ _\\ \_______\ \_______\ \_______\ \_______\  \ \__\       \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\  \ \__\ \ \__\ \_______\ \__\\ \__\
##      \|__|     \|__|\|__|\|_______|\|_______|\|_______|\|_______|   \|__|        \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|   \|__|  \|__|\|_______|\|__| \|__|                                      
## --
##  RPECK 11/02/2024 - ProductCollection Option object
##  Acts as join model between Product and Collection
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Collection Product Join Model
    #
    # Explicit join model linking {XEngine::Shopify::Collection} and {XEngine::Shopify::Product}
    # entities. Manages catalog categorization memberships, positioning order, and bulk graph ingress.
    #
    # == Lifecycle Integration
    # Exposes GraphQL selection fragments natively via {XEngine::Shopify::HasGraphQLRepresentation}.
    #
    class ProductCollection < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Binds endpoints, custom selection fragments, and default pipeline filters.
      expose_graphql single: :collection_product, multiple: :collection_products do
        <<~GRAPHQL
          __typename
          id
          collection_id
          product_id
          position
        GRAPHQL
      end

      # == Associations
      belongs_to :collection, class_name: "XEngine::Shopify::Collection", inverse_of: :collection_products
      belongs_to :product, class_name: "XEngine::Shopify::Product", inverse_of: :collection_products
      belongs_to :shop, class_name: "XEngine::Shopify::Shop", inverse_of: :collection_products, optional: true

      # == Validations
      validates :collection, :product, presence: true
      validates :product_id, uniqueness: { scope: :collection_id }

      # == Scopes
      scope :ordered, -> { order(position: :asc) }
    end
  end
end