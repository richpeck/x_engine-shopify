# :stopdoc:
################################################################
################################################################
##   ________  ________  _________  ___  ________  ________   
##  |\   __  \|\   __  \|\___   ___\\  \|\   __  \|\   ___  \  
##  \ \  \|\  \ \  \|\  \|___ \  \_\ \  \ \  \|\  \ \  \\ \  \ 
##   \ \  \\\  \ \   ____\   \ \  \ \ \  \ \  \\\  \ \  \\ \  \
##    \ \  \\\  \ \  \___|    \ \  \ \ \  \ \  \\\  \ \  \\ \  \
##     \ \_______\ \__\        \ \__\ \ \__\ \_______\ \__\\ \__\
##      \|_______|\|__|         \|__|  \|__|\|_______|\|__| \|__|                                                  
## --
##  RPECK 11/02/2024 - Product Option object
##  Manages product variants selection attributes (e.g., Size, Color)
##  --
##  Ref: https://shopify.dev/docs/api/admin-graphql/2024-01/objects/ProductOption
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Product Option Model
    #
    # Manages product-level display options (e.g., Size, Color, Material) that define
    # permissible variant matrices and positioning order synced down from Shopify.
    #
    # == Lifecycle Integration
    # Exposes GraphQL selection fragments natively via {XEngine::Shopify::HasGraphQLRepresentation}.
    # Options are associated directly with parent products and linked to specific variants through option values.
    #
    class ProductOption < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Binds endpoints, custom selection fragments, and default pipeline filters.
      expose_graphql single: :product_option, multiple: :product_options do
        <<~GRAPHQL
          __typename
          id
          name
          position
          values
        GRAPHQL
      end

      # == Associations
      belongs_to :product, class_name: "XEngine::Shopify::Product", inverse_of: :options
      belongs_to :shop, class_name: "XEngine::Shopify::Shop", inverse_of: :product_options, required: false

      has_many :variant_options, class_name: "XEngine::Shopify::VariantOption", dependent: :destroy, inverse_of: :product_option
      has_many :variants, class_name: "XEngine::Shopify::ProductVariant", through: :variant_options

      # == Validations
      validates :name, :position, presence: true
      validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

      # == Scopes
      scope :ordered, -> { order(position: :asc) }
    end
  end
end