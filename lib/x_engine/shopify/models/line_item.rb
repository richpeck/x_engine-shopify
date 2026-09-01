# :stopdoc:
################################################################
################################################################
##  ___       ___  ________   _______           ___  _________  _______   _____ ______      
## |\  \     |\  \|\   ___  \|\  ___ \         |\  \|\___   ___\\  ___ \ |\   _ \  _   \    
## \ \  \    \ \  \ \  \\ \  \ \   __/|        \ \  \|___ \  \_\ \   __/|\ \  \\\__\ \  \   
##  \ \  \    \ \  \ \  \\ \  \ \  \_|/__       \ \  \   \ \  \ \ \  \_|/_\ \  \\|__| \  \  
##   \ \  \____\ \  \ \  \\ \  \ \  \_|\ \       \ \  \   \ \  \ \ \  \_|\ \ \  \    \ \  \ 
##    \ \_______\ \__\ \__\\ \__\ \_______\       \ \__\   \ \__\ \ \_______\ \__\    \ \__\
##     \|_______|\|__|\|__| \|__|\|_______|        \|__|    \|__|  \|_______|\|__|     \|__|  
##
##  --
##  RPECK 24/06/2026 - LineItem Object
##  Encapsulates individual transaction order rows synced from Shopify.
##  --
##  Ref: https://shopify.dev/docs/api/admin-graphql/2024-01/objects/LineItem
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Line Item Model
    #
    # Domain entity managing individual purchased line items within an {XEngine::Shopify::Order}.
    #
    # Tracks quantity, unit pricing, SKU snapshots, and associated product or variant records.
    # Includes {HasGraphQLRepresentation} to expose selection fields required when parent models 
    # (such as {XEngine::Shopify::Order}) compose nested GraphQL queries or bulk operation payloads.
    #
    # @see XEngine::Shopify::Order
    # @see XEngine::Shopify::Product
    # @see XEngine::Shopify::ProductVariant
    # @see HasGraphQLRepresentation
    #
    class LineItem < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # =========================================================================
      # :section: GraphQL Representation Configuration
      # =========================================================================

      # Configures the single node entrypoint and defines the GraphQL field payload
      # returned when calling +LineItem.graphql_query+.
      expose_graphql single: "node" do
        <<~GRAPHQL
          __typename
          id
          title
          quantity
          sku
          product {
            id: legacyResourceId
          }
          variant {
            id: legacyResourceId
            sku
            title
            inventoryItem {
              cost_price: unitCost {
                amount
              }
              country_of_origin: 	countryCodeOfOrigin
            }
          }
          originalUnitPriceSet {
            shopMoney {
              amount
              currencyCode
            }
          }
          discountedUnitPriceSet {
            shopMoney {
              amount
              currencyCode
            }
          }
        GRAPHQL
      end

      # =========================================================================
      # :section: Associations
      # =========================================================================

      # @!attribute order
      #   @return [XEngine::Shopify::Order] The parent transactional order owning this line item.
      belongs_to :order, 
                 class_name: "XEngine::Shopify::Order", 
                 inverse_of: :line_items, 
                 required: true

      # @!attribute product
      #   @return [XEngine::Shopify::Product, nil] The catalog product record associated with this item.
      belongs_to :product, 
                 class_name: "XEngine::Shopify::Product", 
                 inverse_of: :line_items, 
                 required: false

      # @!attribute variant
      #   @return [XEngine::Shopify::ProductVariant, nil] The specific product variant option purchased.
      belongs_to :variant, 
                 class_name: "XEngine::Shopify::ProductVariant", 
                 inverse_of: :line_items, 
                 required: false, 
                 foreign_key: "product_variant_id"

      # @!attribute refund_line_items
      #   @return [ActiveRecord::Relation<XEngine::Shopify::RefundLineItem>] Associated refund line item tracking rows.
      has_many :refund_line_items, 
               class_name: "XEngine::Shopify::RefundLineItem", 
               inverse_of: :line_item, 
               dependent: :destroy

      # =========================================================================
      # :section: Delegations
      # =========================================================================

      # Delegated product attributes
      delegate :id, :title, to: :product, prefix: true, allow_nil: true

      # Delegated variant attributes
      delegate :id, :title, to: :variant, prefix: true, allow_nil: true
    end
  end
end