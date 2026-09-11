# :stopdoc:
################################################################
################################################################
##   _________  ________  ________     
##  |\___   ___\\   __  \|\   ____\    
##  \|___ \  \_\ \  \|\  \ \  \___|    
##       \ \  \ \ \   __  \ \  \  ___  
##        \ \  \ \ \  \ \  \ \  \|\  \ 
##         \ \__\ \ \__\ \__\ \_______\
##          \|__|  \|__|\|__|\|_______|                                                                   
##  --
##  RPECK 17/01/2024 - Tag object
##  Used to give us the means to interact with various products within the store
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Tag Model
    #
    # Represents normalized taxonomy tag attributes associated across products.
    #
    class Tag < XEngine::Core::Model
      # == Associations
      has_many :product_tags, 
               class_name: "XEngine::Shopify::ProductTag", 
               dependent: :destroy, 
               inverse_of: :tag

      has_many :products, 
               through: :product_tags, 
               class_name: "XEngine::Shopify::Product"

      # == Validations
      validates :name, presence: true, uniqueness: true

      # == Scopes
      scope :alphabetical, -> { order(name: :asc) }
      scope :by_name, ->(term) { where("name ILIKE ?", "%#{sanitize_sql_like(term)}%") }
    end
  end
end