# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  ________  ___  ___  ________ _________  ________      
##  |\   __  \|\   __  \|\   __  \|\   ___ \|\  \|\  \|\   ____\\___   ___\\   ____\     
##  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \___\|___ \  \_\ \  \___|_    
##   \ \   ____\ \   _  _\ \  \\\  \ \  \ \\ \ \  \\\  \ \  \       \ \  \ \ \_____  \   
##    \ \  \___|\ \  \\  \\ \  \\\  \ \  \_\\ \ \  \\\  \ \  \____   \ \  \ \|____|\  \  
##     \ \__\    \ \__\\ _\\ \_______\ \_______\ \_______\ \_______\  \ \__\  ____\_\  \ 
##      \|__|     \|__|\|__|\|_______|\|_______|\|_______|\|_______|   \|__| |\_________\
##                                                                           \|_________|
##  --
##  RPECK 06/06/2026 - Shopify Product Media Migration
##  Defines the schema for product media assets within XEngine.
################################################################
################################################################

# frozen_string_literal: true

# = Shopify Product Database Provisioner
#
# Generates the multi-tenant tracking schema required to store, manage, and query
# base product resources synchronized from the Shopify Admin API layer.
#
# == Schema Layout Matrix
# [id]                 UUID primary key unique to the local engine instance.
# [shop_id]            Foreign key UUID reference matching the owner store model context.
# [shopify_id]         External Shopify Global Identifier (GID) or raw numeric API string.
# [title]              The presentation title string for the product resource.
# [handle]             String slug used for URL building and SEO routing lookups per store.
# [description]        The raw HTML description payload string container.
# [vendor]             The brand or manufacturing vendor identity tracking string.
# [product_type]       Shopify's native high-level classification category descriptor token.
# [status]             State tracking product visibility (e.g., active, draft, archived).
# [price]              The decimal price valuation boundary for tracking transactional summaries.
# [total_inventory]    The aggregate quantity calculation total across active tracking locations.
# [tracks_inventory]   Boolean flag indicating whether the platform monitors allocation metrics.
# [published_at]       Timestamp marker tracking when the product was published to the online channel.
# [featured_image_id]  Numeric Shopify GID pointing directly to the product's primary media asset.
# [created_at]         Standard ActiveRecord timestamp.
# [updated_at]         Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyProducts < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|
      
      t.belongs_to :shop,
                   type: :uuid,
                   foreign_key: { to_table: shop_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Webhook & GraphQL Identifiers
      t.string :shopify_id, null: true

      # Content & Categorization
      t.string :title,       null: false
      t.string :handle,      null: false, index: true
      t.text   :description  # Stores the description HTML payload
      t.string :vendor       # Stores brand/manufacturer
      t.string :product_type # Stores custom categorization

      # Inventory, States, & Operational Metrics
      t.string  :status,          default: "draft"
      t.decimal :price,           precision: 10, scale: 2
      t.integer :total_inventory
      t.boolean :tracks_inventory

      # Associations & Publishing Metrics
      t.datetime :published_at # Tracks visibility timeline metrics
      
      # Unconstrained bigint column to handle streaming GraphQL bulk payloads where
      # Product records land before their corresponding ProductMedia lines are parsed.
      t.bigint   :featured_image_id, null: true, index: true

      t.timestamps

      # Multi-tenant unique composite index for shop_id + shopify_id mapping
      t.index [:shop_id, :shopify_id], unique: true, name: "idx_xe_shopify_products_shop_shopify_id"
    end
  end

  private

  # Resolves the database target table directly from the Product model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::Product.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  #
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

  # Resolves the fully namespaced physical table string value for the +ProductMedia+ resource.
  #
  # @return [String]
  def media_table
    @media_table ||= XEngine::Shopify::ProductMedia.table_name
  end
end