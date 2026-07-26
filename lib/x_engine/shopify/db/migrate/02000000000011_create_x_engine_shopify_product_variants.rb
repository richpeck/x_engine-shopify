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

# = Shopify Product Variant Database Provisioner
#
# Generates the multi-tenant tracking schema required to store, manage, and query
# distinct sellable stock-keeping items synchronized from the Shopify Admin API layer.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:product_variant+
#
# == Schema Layout Matrix
# [id]                 The explicit numeric primary key overridden to store Shopify's GID integer directly.
# [product_id]         The reference link matching the parent catalog product model.
# [featured_image_id]  Foreign key UUID reference pointing directly to the variant's primary media asset.
# [title]              Used to explain what specific choice format the variant represents.
# [sku]                Stock keeping unit alphanumeric tracker string used for third-party logistics.
# [position]           The sorting priority balance integer value assigned by the merchant layout.
# [price]              The explicit listing purchase valuation price in decimal format.
# [cost_price]         The unit operational production expense cost valuation value in decimal format.
# [inventory_policy]   The fallback out-of-stock treatment token pattern passed by Shopify.
# [inventory_quantity] The current physical ledger count balance for items present in stock.
# [country_of_origin]  The standardized ISO tracking territory string code applied to cross-border logistics.
#
# == Architectural Guardrails
# * *Naked BigInt Identifiers:* Overrides the global UUID schema pattern on the base table primary key layer to facilitate raw mathematical integer mappings straight to Shopify's high-volume GID signatures.
# * *Nullification Integrity:* Utilizes <tt>on_delete: :nullify</tt> constraints on the asset relationship layout to ensure background asset pruning commands do not cause cascade deletions of structural inventory variants.
class CreateXEngineShopifyProductVariants < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :product_variant
  
  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up 

    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|
      
      # Core Structural Parent Links
      t.belongs_to :product, type: :bigint, foreign_key: { to_table: product_table, on_delete: :cascade }, null: false, index: true
      t.references :featured_image,
                   type: :uuid,
                   null: true,
                   foreign_key: { to_table: media_table, on_delete: :nullify },
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
    end
  end

  private

  # Resolves the fully namespaced physical table string value for the parent +Product+ resource.
  # @return [String]
  def product_table
    XEngine::Core::Model.table_name_for(:shopify, :product)
  end

  # Resolves the fully namespaced physical table string value for the +ProductMedia+ resource.
  # @return [String]
  def media_table
    XEngine::Core::Model.table_name_for(:shopify, :product_media)
  end
  
end
# :startdoc: