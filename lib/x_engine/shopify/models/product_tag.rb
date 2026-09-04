# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  ________  ___  ___  ________ _________        _________  ________  ________     
##  |\   __  \|\   __  \|\   __  \|\   ___ \|\  \|\  \|\   ____\\___   ___\     |\___   ___\\   __  \|\   ____\    
##  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \___\|___ \  \_|     \|___ \  \_\ \  \|\  \ \  \___|    
##   \ \   ____\ \   _  _\ \  \\\  \ \  \ \\ \ \  \\\  \ \  \       \ \  \           \ \  \ \ \   __  \ \  \  ___  
##    \ \  \___|\ \  \\  \\ \  \\\  \ \  \_\\ \ \  \\\  \ \  \____   \ \  \           \ \  \ \ \  \ \  \ \  \|\  \ 
##     \ \__\    \ \__\\ _\\ \_______\ \_______\ \_______\ \_______\  \ \__\           \ \__\ \ \__\ \__\ \_______\
##      \|__|     \|__|\|__|\|_______|\|_______|\|_______|\|_______|   \|__|            \|__|  \|__|\|__|\|_______|                    
##  --
## RPECK 17/01/2024 - Product Tag object
## Pulls in tag data, which can then be used to populate product tags
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Product Tag Model
    #
    # Encapsulates direct product-to-tag assignments, providing fast indexed string
    # filtering without requiring a standalone tag entity or join table overhead.
    #
    class ProductTag < XEngine::Core::Model
      self.table_name = "shopify_product_tags"

      # == Associations
      belongs_to :product, class_name: "XEngine::Shopify::Product", inverse_of: :product_tags

      # == Validations
      validates :name, presence: true
      validates :name, uniqueness: { scope: :product_id }

      # == Scopes
      scope :by_name, ->(tag_name) { where(name: tag_name) }
    end
  end
end