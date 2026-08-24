# :stopdoc:
################################################################
################################################################
##   ________  ___  ___  ___  ________  ________  ___  ________   ________          ___       ___  ________   _______           ___  _________  _______   _____ ______      
##  |\   ____\|\  \|\  \|\  \|\   __  \|\   __  \|\  \|\   ___  \|\   ____\        |\  \     |\  \|\   ___  \|\  ___ \         |\  \|\___   ___\\  ___ \ |\   _ \  _   \    
##  \ \  \___|\ \  \\\  \ \  \ \  \|\  \ \  \|\  \ \  \ \  \\ \  \ \  \___|        \ \  \    \ \  \ \  \\ \  \ \   __/|        \ \  \|___ \  \_\ \   __/|\ \  \\\__\ \  \   
##   \ \_____  \ \   __  \ \  \ \   ____\ \   ____\ \  \ \  \\ \  \ \  \  ___       \ \  \    \ \  \ \  \\ \  \ \  \_|/__       \ \  \   \ \  \ \ \  \_|/_\ \  \\|__| \  \  
##    \|____|\  \ \  \ \  \ \  \ \  \___|\ \  \___|\ \  \ \  \\ \  \ \  \|\  \       \ \  \____\ \  \ \  \\ \  \ \  \_|\ \       \ \  \   \ \  \ \ \  \_|\ \ \  \    \ \  \ 
##      ____\_\  \ \__\ \__\ \__\ \__\    \ \__\    \ \__\ \__\\ \__\ \_______\       \ \_______\ \__\ \__\\ \__\ \_______\       \ \__\   \ \__\ \ \_______\ \__\    \ \__\
##     |\_________\|__|\|__|\|__|\|__|     \|__|     \|__|\|__| \|__|\|_______|        \|_______|\|__|\|__| \|__|\|_______|        \|__|    \|__|  \|_______|\|__|     \|__|
##     \|_________|                                                                                                                                                              
##                                                                                                                                                
## RPECK 17/01/2024 - ShippingLineItem object
## Populates the order with various line item objects from Shopify
## --
## Ref: https://shopify.dev/docs/api/storefront/2024-01/objects/OrderLineItem
####################################
####################################

# frozen_string_literal: true

module XEngine
  module Shopify
    # Represents a shipping charges line item within a Shopify {XEngine::Shopify::Order}.
    #
    # Inherits core line item behaviors from {XEngine::Shopify::LineItem} and includes
    # {HasGraphQLRepresentation} to provide the required GraphQL fragment definition
    # consumed during dynamic bulk query building in {XEngine::Shopify::BulkOperation}.
    #
    # @see XEngine::Shopify::LineItem
    # @see XEngine::Shopify::BulkOperation
    # @see HasGraphQLRepresentation
    class ShippingLineItem < LineItem
      include HasGraphQLRepresentation

      # =========================================================================
      # :section: Callbacks
      # =========================================================================

      before_save ->(shipping_line) { shipping_line.cost_price = 0.00 unless shipping_line.cost_price }

      # =========================================================================
      # :section: GraphQL Representation Configuration
      # =========================================================================

      # Expose single node lookup endpoint and return the multiline selection string
      # directly within the mandatory execution block.
      expose_graphql(single: "node") do
        <<~GRAPHQL
          __typename
          id
          title
          code
          carrierIdentifier
          deliveryCategory
          discountedPriceSet {
            shopMoney {
              amount
              currencyCode
            }
          }
          originalPriceSet {
            shopMoney {
              amount
              currencyCode
            }
          }
        GRAPHQL
      end

      # Attribute type transformations applied during GraphQL response hydration
      graphql_attribute_transforms(
        price: :to_d,
        discounted_price: :to_d,
        cost_price: :to_d
      )
    end
  end
end