####################################
####################################
##    ___      ___ ________  ________  ___  ________  ________   _________        ________  ________  _________  ___  ________  ________          
##   |\  \    /  /|\   __  \|\   __  \|\  \|\   __  \|\   ___  \|\___   ___\     |\   __  \|\   __  \|\___   ___\\  \|\   __  \|\   ___  \        
##   \ \  \  /  / | \  \|\  \ \  \|\  \ \  \ \  \|\  \ \  \\ \  \|___ \  \_|     \ \  \|\  \ \  \|\  \|___ \  \_\ \  \ \  \|\  \ \  \\ \  \       
##    \ \  \/  / / \ \   __  \ \   _  _\ \  \ \   __  \ \  \\ \  \   \ \  \       \ \  \\\  \ \   ____\   \ \  \ \ \  \ \  \\\  \ \  \\ \  \      
##     \ \    / /   \ \  \ \  \ \  \\  \\ \  \ \  \ \  \ \  \\ \  \   \ \  \       \ \  \\\  \ \  \___|    \ \  \ \ \  \ \  \\\  \ \  \\ \  \     
##      \ \__/ /     \ \__\ \__\ \__\\ _\\ \__\ \__\ \__\ \__\\ \__\   \ \__\       \ \_______\ \__\        \ \__\ \ \__\ \_______\ \__\\ \__\    
##       \|__|/       \|__|\|__|\|__|\|__|\|__|\|__|\|__|\|__| \|__|    \|__|        \|_______|\|__|         \|__|  \|__|\|_______|\|__| \|__|    
##                                                                                                                                               
## RPECK 11/02/2024 - Variant Options
## Join table used to provide the means to connect a variant and the options that a product may have
## --
## Ref: https://shopify.dev/docs/api/admin-graphql/2024-01/objects/ProductOption
####################################
####################################

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Variant Option Model
    #
    # Acts as a relational join model bridging product variants with specific product options.
    # Represents the explicit value selection (e.g., +"Red"+, +"Large"+, +"Cotton"+) mapping a 
    # {XEngine::Shopify::ProductVariant} to its corresponding {XEngine::Shopify::ProductOption}.
    #
    # == Attributes
    #
    # [id]
    #   Internal auto-increment primary key for the join record.
    # [product_variant_id]
    #   Foreign key referencing the parent {XEngine::Shopify::ProductVariant}.
    # [product_option_id]
    #   Foreign key referencing the associated {XEngine::Shopify::ProductOption}.
    # [value]
    #   The string value assigned to this option choice for the given variant (e.g., +"Blue"+).
    # [created_at]
    #   Timestamp detailing when the join record was persisted.
    # [updated_at]
    #   Timestamp detailing when the join record was last modified.
    #
    # == Associations
    #
    # [variant]
    #   The {XEngine::Shopify::ProductVariant} owning this specific option setting.
    # [product_option]
    #   The overarching {XEngine::Shopify::ProductOption} dimension defining this value.
    #
    class VariantOption < XEngine::Core::Model

      # =======================================================================
      # Associations
      # =======================================================================

      # @!attribute [rw] variant
      #   @return [XEngine::Shopify::ProductVariant] The parent product variant record.
      belongs_to :variant, 
                 class_name: 'XEngine::Shopify::ProductVariant',
                 foreign_key: 'product_variant_id'

      # @!attribute [rw] product_option
      #   @return [XEngine::Shopify::ProductOption] The underlying product option dimension.
      belongs_to :product_option, 
                 class_name: 'XEngine::Shopify::ProductOption',
                 foreign_key: 'product_option_id'

      # =======================================================================
      # Validations
      # =======================================================================

      validates :value, presence: true

    end
  end
end