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
    # Manages purchased variants, units, pricing dimensions, and inventory snapshots.
    # Exposes associations down to tracking tables for downstream analytical mapping.
    #
    class LineItem < XEngine::Core::Model

      # Registers the class context as an active shopify resource entity layer
      expose_as :shopify, :line_item

      # == Associations
      belongs_to :order, class_name: "XEngine::Shopify::Order", inverse_of: :line_items, required: true
      belongs_to :product, class_name: "XEngine::Shopify::Product", inverse_of: :line_items, required: false
      belongs_to :variant, class_name: "XEngine::Shopify::ProductVariant", inverse_of: :line_items, required: false, foreign_key: "product_variant_id"
      
      has_many :refund_line_items, class_name: "XEngine::Shopify::RefundLineItem", inverse_of: :line_item, dependent: :destroy

      # == Delegations
      delegate :id, :title, to: :product, prefix: true, allow_nil: true
      delegate :id, :title, to: :variant, prefix: true, allow_nil: true
    end
  end
end
# :startdoc: