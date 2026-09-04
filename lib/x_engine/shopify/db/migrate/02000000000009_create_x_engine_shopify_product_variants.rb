# :stopdoc:
####################################
####################################
##  ___      ___ ________  ________  ___  ________  ________   _________   
## |\  \    /  /|\   __  \|\   __  \|\  \|\   __  \|\   ___  \|\___   ___\ 
## \ \  \  /  / | \  \|\  \ \  \|\  \ \  \ \  \|\  \ \  \\ \  \|___ \  \_| 
##  \ \  \/  / / \ \   __  \ \   _  _\ \  \ \   __  \ \  \\ \  \   \ \  \  
##   \ \    / /   \ \  \ \  \ \  \\  \\ \  \ \  \ \  \ \  \\ \  \   \ \  \ 
##    \ \__/ /     \ \__\ \__\ \__\\ _\\ \__\ \__\ \__\ \__\\ \__\   \ \__\
##     \|__|/       \|__|\|__|\|__|\|__|\|__|\|__|\|__|\|__| \|__|    \|__|
##
##  --                                                                  
##  RPECK 06/06/2026 - Shopify Product Variant Migration
##  Defines the schema for product variant items within XEngine.
####################################
####################################

# frozen_string_literal: true

# = Shopify Product Variant Database Provisioner
#
# Generates the multi-tenant tracking schema required to store, manage, and query
# distinct sellable stock-keeping items synchronized from the Shopify Admin API layer (+XEngine::Shopify::ProductVariant+).
#
# == Schema Layout Matrix
# [id]                 Bigint primary key matching the naked numeric Shopify GID identifier.
# [shop_id]            Foreign key UUID reference matching the owner store model context.
# [product_id]         Foreign key bigint reference matching the parent catalog product model.
# [title]              Used to explain what specific choice format the variant represents.
# [sku]                Stock keeping unit alphanumeric tracker string used for third-party logistics.
# [barcode]            Product barcode identifier string.
# [position]           The sorting priority balance integer value assigned by the merchant layout.
# [price]              The explicit listing purchase valuation price in decimal format.
# [cost_price]         The unit operational production expense cost valuation value in decimal format.
# [inventory_policy]   The fallback out-of-stock treatment token pattern passed by Shopify.
# [inventory_quantity] The current physical ledger count balance for items present in stock.
# [country_of_origin]  The standardized ISO tracking territory string code applied to cross-border logistics.
# [created_at]         Standard ActiveRecord timestamp.
# [updated_at]         Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyProductVariants < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|
      
      # Multi-Tenant & Core Structural Parent Links
      t.belongs_to :shop,
                   type: :uuid,
                   foreign_key: { to_table: shop_table, on_delete: :cascade },
                   null: false,
                   index: true

      t.belongs_to :product,
                   type: :bigint,
                   foreign_key: { to_table: product_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Variant Identification Parameters
      t.string  :title, null: false
      t.string  :sku
      t.string  :barcode
      t.integer :position, default: 0

      # Pricing & Cost Sizing Metrics
      t.decimal :price,      precision: 10, scale: 2
      t.decimal :cost_price, precision: 10, scale: 2

      # Inventory Configurations
      t.string  :inventory_policy
      t.integer :inventory_quantity, default: 0
      t.string  :country_of_origin

      t.timestamps

      # Indexes to guarantee rapid warehouse tracking operations
      t.index :sku, name: "idx_xe_shopify_variants_sku"

      # Compound multi-tenant lookup index matching Shopify ingress requirements
      t.index [:shop_id, :id], unique: true, name: "index_#{table_name}_on_shop_id_and_id"
    end
  end

  private

  # Resolves the database target table directly from the ProductVariant model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::ProductVariant.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  #
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Product+ resource.
  #
  # @return [String]
  def product_table
    @product_table ||= XEngine::Shopify::Product.table_name
  end

  # Resolves the fully namespaced physical table string value for the +ProductMedia+ resource.
  #
  # @return [String]
  def media_table
    @media_table ||= XEngine::Shopify::ProductMedia.table_name
  end
  
end