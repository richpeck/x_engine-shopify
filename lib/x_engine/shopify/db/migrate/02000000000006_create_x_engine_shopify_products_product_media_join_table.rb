# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  ________  ___  ___  ________ _________        _____ ______   _______   ________  ___  ________     
##  |\   __  \|\   __  \|\   __  \|\   ___ \|\  \|\  \|\   ____\\___   ___\     |\   _ \  _   \|\  ___ \ |\   ___ \|\  \|\   __  \    
##  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \___\|___ \  \_|     \ \  \\\__\ \  \ \   __/|\ \  \_|\ \ \  \ \  \|\  \   
##   \ \   ____\ \   _  _\ \  \\\  \ \  \ \\ \ \  \\\  \ \  \       \ \  \       \ \  \\|__| \  \ \  \_|/_\ \  \ \\ \ \  \ \   __  \  
##    \ \  \___|\ \  \\  \\ \  \\\  \ \  \_\\ \ \  \\\  \ \  \____   \ \  \       \ \  \    \ \  \ \  \_|\ \ \  \_\\ \ \  \ \  \ \  \ 
##     \ \__\    \ \__\\ _\\ \_______\ \_______\ \_______\ \_______\  \ \__\       \ \__\    \ \__\ \_______\ \_______\ \__\ \__\ \__\
##      \|__|     \|__|\|__|\|_______|\|_______|\|_______|\|_______|   \|__|        \|__|     \|__|\|_______|\|_______|\|__|\|__|\|__|                   
## --
## RPECK 21/01/2024 - ProductsTags datatable
## Defines the relational HABTM bridge layout table mapping products to tag classifiers within XEngine.
################################################################
################################################################

# = Shopify Product Media Association Join Table Provisioner
#
# Generates the relational bridge table mapping shopify product models to their
# respective asset media records in a multi-tenant many-to-many lookup topology.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:products_product_media+
#
# == Schema Layout Matrix
# [product_id]        Foreign key reference pointing to the parent Product. Constrained to <tt>bigint</tt> to match Shopify's naked ID strategy.
# [product_media_id]  Foreign key reference pointing to the asset ProductMedia. Maps to the global engine standard <tt>uuid</tt> strategy.
#
# == Architectural Guardrails
# * *Cascade Deletion:* Drops the relationship records automatically if either the parent product or media record is destroyed.
# * *Index Size Ceiling:* Explicitly overrides index names to bypass PostgreSQL's strict 63-character limit constraint rule.
class CreateXEngineShopifyProductsProductMediaJoinTable < XEngine::Core::Database::Migration

  # Enforce structural namespacing parameters for the join table layout target
  set_resource :shopify, :products_product_media

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Force id: false to eliminate standard auto-incrementing / UUID primary key blocks
    localized_options = table_options.merge(id: false)

    create_table table_name, **localized_options do |t|
      
      # 1. Foreign key pointing to the Product table (CRITICAL: Must be :bigint to match Shopify's naked ID)
      t.references :product,
                   type: :bigint,
                   null: false,
                   foreign_key: { to_table: product_table, on_delete: :cascade }

      # 2. Foreign key pointing to the ProductMedia table (Matches global uuid standard)
      t.references :product_media,
                   type: :uuid,
                   null: false,
                   foreign_key: { to_table: media_table, on_delete: :cascade }

      # 3. Composite index optimizing fast bidirectional filtering lookups
      t.index [:product_id, :product_media_id],
              name: "idx_xe_shopify_prod_media_poly",
              unique: true

    end
  end

  private

  # Resolves the fully namespaced physical table string value for the Product resource.
  #
  # @return [String]
  def product_table
    XEngine::Core::Model.table_name_for(:shopify, :product)
  end

  # Resolves the fully namespaced physical table string value for the ProductMedia resource.
  #
  # @return [String]
  def media_table
    XEngine::Core::Model.table_name_for(:shopify, :product_media)
  end

end
# :startdoc: