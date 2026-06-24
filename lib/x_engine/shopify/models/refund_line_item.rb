# :stopdoc:
################################################################
################################################################
##  ________  _______   ________ ___  ___  ________   ________          ___       ___  ________   _______           ___  _________  _______   _____ ______          
## |\   __  \|\  ___ \ |\  _____\\  \|\  \|\   ___  \|\   ___ \        |\  \     |\  \|\   ___  \|\  ___ \         |\  \|\___   ___\\  ___ \ |\   _ \  _   \        
## \ \  \|\  \ \   __/|\ \  \__/\ \  \\\  \ \  \\ \  \ \  \_|\ \       \ \  \    \ \  \ \  \\ \  \ \   __/|        \ \  \|___ \  \_\ \   __/|\ \  \\\__\ \  \       
##  \ \   _  _\ \  \_|/_\ \   __\\ \  \\\  \ \  \\ \  \ \  \ \\ \       \ \  \    \ \  \ \  \\ \  \ \  \_|/__       \ \  \   \ \  \ \ \  \_|/_\ \  \\|__| \  \      
##   \ \  \\  \\ \  \_|\ \ \  \_| \ \  \\\  \ \  \\ \  \ \  \_\\ \       \ \  \____\ \  \ \  \\ \  \ \  \_|\ \       \ \  \   \ \  \ \ \  \_|\ \ \  \    \ \  \     
##    \ \__\\ _\\ \_______\ \__\   \ \_______\ \__\\ \__\ \_______\       \ \_______\ \__\ \__\\ \__\ \_______\       \ \__\   \ \__\ \ \_______\ \__\    \ \__\    
##     \|__|\|__|\|_______|\|__|    \|_______|\|__| \|__|\|_______|        \|_______|\|__|\|__| \|__|\|_______|        \|__|    \|__|  \|_______|\|__|     \|__|           
##                                                                                                                                                 
##  --
##  RPECK 24/06/2026 - RefundLineItem Object
##  Tracks structural sub-allocations of individual returned line items for precise tax calculations.
##  --
##  Ref: https://shopify.dev/docs/api/admin-graphql/2024-01/objects/RefundLineItem
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Refund Line Item Model
    #
    # Bridges specific line item rows back to parent ledger refund rollbacks.
    # Preserves discrete item quantities and subtotals to backstop downstream VAT audit verification loops.
    #
    class RefundLineItem < XEngine::Core::Model

      # Registers the class context as an active shopify resource entity layer
      expose_as :shopify, :refund_line_item

      # == Associations
      # Explicit relation bounds mapping the line reversion profile to core records
      belongs_to :refund, class_name: "XEngine::Shopify::Refund", inverse_of: :refund_line_items, required: true
      belongs_to :line_item, class_name: "XEngine::Shopify::LineItem", inverse_of: :refund_line_items, required: true
    end
  end
end
# :startdoc: