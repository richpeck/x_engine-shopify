####################################
####################################
##  ___      ___ ________  ________  ___  ________  ________   _________   
## |\  \    /  /|\   __  \|\   __  \|\  \|\   __  \|\   ___  \|\___   ___\ 
## \ \  \  /  / | \  \|\  \ \  \|\  \ \  \ \  \|\  \ \  \\ \  \|___ \  \_| 
##  \ \  \/  / / \ \   __  \ \   _  _\ \  \ \   __  \ \  \\ \  \   \ \  \  
##   \ \    / /   \ \  \ \  \ \  \\  \\ \  \ \  \ \  \ \  \\ \  \   \ \  \ 
##    \ \__/ /     \ \__\ \__\ \__\\ _\\ \__\ \__\ \__\ \__\\ \__\   \ \__\
##     \|__|/       \|__|\|__|\|__|\|__|\|__|\|__|\|__|\|__| \|__|    \|__|
##                                                                  
## RPECK 18/01/2024 - ProductVariant object
## Allows us to allocate variant-specific information to a product
## --
## Ref: https://shopify.dev/docs/api/admin-graphql/2024-01/objects/ProductVariant
####################################
####################################

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Product Variant Model
    #
    # Tracks distinct sellable stock-keeping items tied to parent configurations, managing 
    # granular pricing structures, unit cost evaluation thresholds, international country metadata, 
    # and warehouse inventory counts.
    #
    # == Lifecycle Integration
    # This resource states its field-level footprint definitions natively through the 
    # {XEngine::Shopify::HasGraphQLRepresentation} mixin. It runs strictly as an encapsulated 
    # child fragment template within upstream parent bulk operation contexts.
    #
    class ProductVariant < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Defined strictly as a sub-selection block structure for nested pipeline arrays.
      expose_graphql do
        <<~GRAPHQL
          __typename
          id
          legacy_id: legacyResourceId
          title
          position
          price
          sku
          barcode
          product_id: product {
            id: legacyResourceId
          }
          inventory_policy: inventoryPolicy
          inventory_quantity: inventoryQuantity
          selectedOptions {
            name
            value
          }
          media(first: 1) {
            edges {
              node {
                __typename
                id
              }
            }
          }
          inventoryItem {
            country_of_origin: countryCodeOfOrigin
            cost_price: unitCost {
              amount
            }
          }
          created_at: createdAt
        GRAPHQL
      end

      # == Associations
      belongs_to :product, class_name: "XEngine::Shopify::Product", inverse_of: :variants
      belongs_to :featured_image, class_name: "XEngine::Shopify::ProductMedia", foreign_key: :featured_media_id, required: false

      has_one :shop, through: :product, class_name: "XEngine::Shopify::Shop"

      has_many :options, class_name: "XEngine::Shopify::VariantOption", dependent: :destroy
      has_many :line_items, class_name: "XEngine::Shopify::LineItem", foreign_key: "product_variant_id", inverse_of: :variant

      has_many :orders, class_name: "XEngine::Shopify::Order", through: :line_items

      # == Delegations
      delegate :shop, :shop_id, to: :product, allow_nil: true
      delegate :url, to: :featured_image, prefix: true, allow_nil: true
    end
  end
end