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
      expose_graphql single: :product, multiple: :products do
        <<~GRAPHQL
          __typename
          id
          legacy_id: legacyResourceId
          handle
          title
          tags
          status
          description: descriptionHtml
          vendor
          product_type: productType
          total_inventory: totalInventory
          tracks_inventory: tracksInventory
          created_at: createdAt
          published_at: publishedAt
          media_count: mediaCount {
            count 
          }
          price: priceRangeV2 {
            min: minVariantPrice { amount }
            max: maxVariantPrice { amount }
          }

          options(first:250) {
            id
            name
            position
          }
          
          media(first:250) {
            edges {
              node {
                #{XEngine::Shopify::ProductMedia.graphql_query}
              }
            }
          }

          featured_image_id: featuredMedia {
            id
          }

          collections(first: 250) {
            edges {
              node {
                #{XEngine::Shopify::Collection.graphql_query}
              }
            }
          }
          variants(first: 250) {
            edges {
              node {
                #{XEngine::Shopify::ProductVariant.graphql_query}
              }
            }
          }
          
          metafields(first: 250) {
            edges {
              node {
                #{XEngine::Shopify::Metafield.graphql_query}
              }
            }
          }
        GRAPHQL
      end

      # == Enums
      # String-backed enum aligns directly with Shopify string values and DB string columns
      enum :status, {
        active: "active",
        draft: "draft",
        archived: "archived",
        unlisted: "unlisted"
      }, default: :draft

      # Override setter to normalize upper-case GraphQL values ("ACTIVE" -> "active")
      def status=(value)
        super(value.to_s.downcase)
      rescue ArgumentError
        super("draft")
      end

      # == Associations
      belongs_to :shop, class_name: "XEngine::Shopify::Shop", inverse_of: :products
      belongs_to :featured_image,
                 class_name: "XEngine::Shopify::ProductMedia",
                 optional: true

      has_many :product_tags, class_name: "XEngine::Shopify::ProductTag", dependent: :destroy, inverse_of: :product
      has_and_belongs_to_many :collections, -> { distinct }, class_name: "XEngine::Shopify::Collection"

      has_many :line_items, class_name: "XEngine::Shopify::LineItem", inverse_of: :product
      has_many :variants, class_name: "XEngine::Shopify::ProductVariant", dependent: :destroy, inverse_of: :product
      has_many :options, class_name: "XEngine::Shopify::ProductOption", dependent: :destroy, inverse_of: :product
      has_many :metafields, class_name: "XEngine::Shopify::Metafield", dependent: :destroy, as: :objectable

      has_many :orders, class_name: "XEngine::Shopify::Order", through: :line_items
      has_many :product_media, class_name: "XEngine::Shopify::ProductMedia", through: :shop

      # == Validations
      validates :shopify_id, presence: true, uniqueness: { scope: :shop_id }
      validates :handle, :title, presence: true

      # == Delegations
      delegate :url, to: :featured_image, prefix: true, allow_nil: true

      # == Scopes
      # Filter products containing a specific tag string
      scope :with_tag, ->(tag_name) {
        joins(:product_tags).where(shopify_product_tags: { name: tag_name })
      }

      # Compiles a local, source-of-truth availability check bypassing unstable platform cached states.
      scope :available, ->(direction = true) {
        if direction
          where(tracks_inventory: false).or(where(tracks_inventory: true).where("total_inventory > 0"))
        else
          where(tracks_inventory: true).where("total_inventory <= 0")
        end
      }

      # Helper method to retrieve array of tag name strings directly
      def tags
        product_tags.pluck(:name)
      end
    end
  end
end