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

# = Shopify Product Database Provisioner
#
# Generates the multi-tenant tracking schema required to store, manage, and query
# base product resources synchronized from the Shopify Admin API layer.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:product+
#
# == Schema Layout Matrix
# [id]                The explicit numeric primary key overridden to store Shopify's GID integer directly.
# [shop_id]           The reference link matching the owner store model.
# [title]             The presentation title name text string for the resource.
# [handle]            Unique string slug used for URL building and SEO routing lookups.
# [body_html]         The raw description rich-text content payload string container.
# [vendor]            The brand or manufacturing vendor identity tag tracking string.
# [product_type]      Shopify's native high-level classification category descriptor token.
# [status]            State mapping integer tracking product visibility (e.g., active, draft, archived).
# [price]             The decimal price valuation boundary for tracking transactional summaries.
# [total_inventory]   The aggregate quantity calculation total across multiple active tracking locations.
# [tracks_inventory]  Boolean flag indicating whether the platform monitors allocation metrics.
# [published_at]      Timestamp marker tracking exactly when the product was exposed to the online channel grid.
# [featured_image_id] Foreign key UUID reference pointing directly to the product's primary media asset.
#
# == Architectural Guardrails
# * *Naked BigInt Identifiers:* Overrides the global UUID schema pattern on the base table primary key layer to facilitate raw mathematical integer mappings straight to Shopify's high-volume GID signatures.
# * *Nullification Integrity:* Utilizes <tt>on_delete: :nullify</tt> constraints on the asset relationship layout to ensure background asset pruning commands do not cause cascade deletions of structural catalog products.
class CreateXEngineShopifyProducts < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :product
	
  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up 

    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|
			
      t.belongs_to :shop, type: :uuid, foreign_key: { to_table: shop_table, on_delete: :cascade }, null: false, index: true
      
      # Webhook Identifiers & Content Layout Data
      t.string  :title,            null: false	
      t.string  :handle,           null: false
      t.text    :body_html                      # Stores the description HTML payload
      t.string  :vendor                         # Stores brand/manufacturer
      t.string  :product_type                   # Stores custom categorization

      # Inventory, States, & Operational Metrics
      t.integer :status
      t.decimal :price,            precision: 10, scale: 2
      t.integer :total_inventory
      t.boolean :tracks_inventory
      
      # Associations & Publishing Metrics
      t.datetime :published_at                  # Tracks visibility timeline metrics
      t.references :featured_image,
                   type: :uuid,
                   null: true,
                   foreign_key: { to_table: media_table, on_delete: :nullify },
                   index: true

      t.timestamps 

      # Added to give us the ability to scope uniqueness safely around order name parameters per-tenant
      t.index [:shop_id, :handle], unique: true, name: "idx_xe_shopify_products_shop_handle"
			
    end
  end

  private

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  # @return [String]
  def shop_table
    XEngine::Core::Model.table_name_for(:shopify, :shop)
  end

  # Resolves the fully namespaced physical table string value for the +ProductMedia+ resource.
  # @return [String]
  def media_table
    XEngine::Core::Model.table_name_for(:shopify, :product_media)
  end
	
end
# :startdoc: