# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  _______   ________  ________      
##  |\   __  \|\   __  \|\   ___ \|\  ___ \ |\   __  \|\   ____\     
##  \ \  \|\  \ \  \|\  \ \  \_|\ \ \   __/|\ \  \|\  \ \  \___|_    
##   \ \  \\\  \ \   _  _\ \  \ \\ \ \  \_|/_\ \   _  _\ \_____  \   
##    \ \  \\\  \ \  \\  \\ \  \_\\ \ \  \_|\ \ \  \\  \\|____|\  \  
##     \ \_______\ \__\\ _\\ \_______\ \_______\ \__\\ _\ ____\_\  \ 
##      \|_______|\|__|\|__|\|_______|\|_______|\|__|\|__|\_________\
##                                                       \|_________|
##  --
##  RPECK 09/07/2026 - Shopify Order Model
##  Domain entity managing transactional store orders, currency values, and sub-resource mappings.
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Order Model
    #
    # Domain entity managing core order metrics, financial checkout balances, fulfillment 
    # tracking statuses, and complex macro relational data trees.
    #
    class Order < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # ---
      # :section: Resource Configuration
      # ---

      # Define the explicit infrastructure table boundaries inside the core schema engine layout.
      set_resource :shopify, :order

      # ---
      # :section: GraphQL Layout Declarations
      # ---

      expose_graphql single: :order, multiple: :orders do
        <<~GRAPHQL
          __typename
          id
          legacy_id: legacyResourceId
          name
          created_at: createdAt
          payment_gateways: paymentGatewayNames
          shipping_country: shippingAddress {
            countryCodeV2
          }
          currency: currencyCode
          fulfillment_status: displayFulfillmentStatus
          financial_status: displayFinancialStatus
          subtotal: subtotalPrice
          total_shipping: totalShippingPriceSet {
            shopMoney {
              amount
            }
          }
          total_tax: totalTaxSet {
            shopMoney {
              amount
            }
          }
          total_refunded_amount: totalRefundedSet {
            shopMoney {
              amount
            }
          }
          total_order_value: totalReceivedSet {
            shopMoney {
              amount
            }
          }
          
          shipping_line_items: shippingLines(first: 250) {
            edges {
              node {
                #{XEngine::Shopify::ShippingLineItem.graphql_fragment.indent(16)}
              }
            }
          }
          
          transactions {
            #{XEngine::Shopify::OrderTransaction.graphql_fragment.indent(12)}
          }
          
          line_items: lineItems(first: 250) {
            edges {
              node {
                #{XEngine::Shopify::LineItem.graphql_fragment.indent(16)}
              }
            }
          }
          
          refunds {
            #{XEngine::Shopify::Refund.graphql_fragment.indent(12)}
          }
          
          fulfillments {
            #{XEngine::Shopify::Fulfillment.graphql_fragment.indent(12)}
          }
        GRAPHQL
      end

      # ---
      # :section: Associations
      # ---

      belongs_to :shop,
                 foreign_key: :shop_id,
                 class_name: "XEngine::Shopify::Shop",
                 inverse_of: :orders

      has_many :line_items,
               foreign_key: :order_id,
               class_name: "XEngine::Shopify::LineItem",
               dependent: :destroy,
               inverse_of: :order

      has_many :fulfillments,
               foreign_key: :order_id,
               class_name: "XEngine::Shopify::Fulfillment",
               dependent: :destroy,
               inverse_of: :order

      has_many :transactions,
               foreign_key: :order_id,
               class_name: "XEngine::Shopify::OrderTransaction",
               dependent: :destroy,
               inverse_of: :order

      has_many :refunds,
               foreign_key: :order_id,
               class_name: "XEngine::Shopify::Refund",
               dependent: :destroy,
               inverse_of: :order

      has_many :shipping_line_items,
               foreign_key: :order_id,
               class_name: "XEngine::Shopify::ShippingLineItem",
               dependent: :destroy,
               inverse_of: :order

      # ---
      # :section: Relational Extensions
      # ---

      has_many :variants, class_name: "XEngine::Shopify::ProductVariant", through: :line_items, source: :variant
      has_many :products, class_name: "XEngine::Shopify::Product", through: :line_items, source: :product

      # ---
      # :section: Attributes Configuration
      # ---

      alias_attribute :number, :name

      accepts_nested_attributes_for :line_items, allow_destroy: false, update_only: true

      delegate :name, :myshopify_domain, :email, :url, :description, :billing_address, :billing_company,
               :billing_city, :billing_phone, :billing_zip, :billing_country, to: :shop, prefix: true

      # ---
      # :section: Validations
      # ---

      validates :shop, :name, :currency, presence: true

    end
  end
end
# :startdoc: