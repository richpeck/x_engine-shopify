# :stopdoc:
################################################################
################################################################
##  ________  ________  ________  ________  ___  ___  ________ _________   
## |\   __  \|\   __  \|\   __  \|\   ___ \|\  \|\  \|\   ____\\___   ___\ 
## \ \  \|\  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \___\|___ \  \_| 
##  \ \   ____\ \   _  _\ \  \\\  \ \  \ \\ \ \  \\\  \ \  \       \ \  \  
##   \ \  \___|\ \  \\  \\ \  \\\  \ \  \_\\ \ \  \\\  \ \  \____   \ \  \ 
##    \ \__\    \ \__\\ _\\ \_______\ \_______\ \_______\ \_______\  \ \__\
##     \|__|     \|__|\|__|\|_______|\|_______|\|_______|\|_______|   \|__|                                                                         
##  --
##  RPECK 17/01/2024 - Product object
##  Used to give us the means to interact with various products within the store
##  --
##  Ref: https://shopify.dev/docs/api/admin-graphql/2024-01/objects/Product
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Product Model
    #
    # Encapsulates core e-commerce marketplace items, managing variants, pricing metrics,
    # taxonomy tags, stock levels, and associated media assets synced down from Shopify.
    #
    # == Lifecycle Integration
    # This resource encapsulates its GraphQL representation layouts natively via 
    # {XEngine::Shopify::HasGraphQLRepresentation}. Handles are preserved directly 
    # from incoming platform payloads.
    #
    class Product < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Binds endpoints, custom selection fragments, and default pipeline filters.
      expose_graphql single: :product, multiple: :products, default_filter: "status:active" do
        <<~GRAPHQL
          __typename
          id
          legacy_id: legacyResourceId
          handle
          title
          tags
          status
          total_inventory: totalInventory
          tracks_inventory: tracksInventory
          created_at: createdAt
          price: priceRangeV2 {
            min: minVariantPrice { amount }
            max: maxVariantPrice { amount }
          }
          options {
            id
            name
            position
          }
          
          # Modernized polymorphic asset timeline connection layer
          media(first: 100) {
            nodes {
              #{XEngine::Shopify::ProductMedia.graphql_fragment.indent(14)}
            }
          }

          featured_image: featuredImage {
            id
          }
          collections(first: 250) {
            edges {
              node {
                #{XEngine::Shopify::Collection.graphql_fragment.indent(16)}
              }
            }
          }
          variants(first: 250) {
            edges {
              node {
                #{XEngine::Shopify::ProductVariant.graphql_fragment.indent(16)}
              }
            }
          }
          
          # Modernized nested fragment tracking for company import workflows
          metafields(first: 250) {
            edges {
              node {
                #{XEngine::Shopify::Metafield.graphql_fragment.indent(16)}
              }
            }
          }
        GRAPHQL
      end

      # == Enums
      enum :status, { active: 0, draft: 1, archived: 2, unlisted: 3 }, default: :draft

      # == Associations
      belongs_to :shop, class_name: "XEngine::Shopify::Shop", inverse_of: :products
      belongs_to :featured_image, class_name: "XEngine::Shopify::ProductMedia", required: false

      has_and_belongs_to_many :tags, -> { distinct }, class_name: "XEngine::Shopify::Tag"
      has_and_belongs_to_many :collections, -> { distinct }, class_name: "XEngine::Shopify::Collection"

      has_many :line_items, class_name: "XEngine::Shopify::LineItem", inverse_of: :product
      has_many :variants, class_name: "XEngine::Shopify::ProductVariant", dependent: :destroy, inverse_of: :product
      has_many :options, class_name: "XEngine::Shopify::ProductOption", dependent: :destroy, inverse_of: :product
      has_many :metafields, class_name: "XEngine::Shopify::Metafield", dependent: :destroy, as: :objectable

      has_many :orders, class_name: "XEngine::Shopify::Order", through: :line_items
      has_many :product_media, class_name: "XEngine::Shopify::ProductMedia", through: :shop

      # == Validations
      validates :handle, :title, presence: true

      # == Delegations
      delegate :url, to: :featured_image, prefix: true, allow_nil: true

      # == Scopes
      # Compiles a local, source-of-truth availability check bypassing unstable platform cached states.
      scope :available, ->(direction = true) {
        if direction
          where(tracks_inventory: false).or(where(tracks_inventory: true).where("total_inventory > 0"))
        else
          where(tracks_inventory: true).where("total_inventory <= 0")
        end
      }
    end
  end
end