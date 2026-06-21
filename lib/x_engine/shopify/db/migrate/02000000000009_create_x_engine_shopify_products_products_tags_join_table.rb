# :stopdoc:
################################################################
################################################################
##      ___  ________  ___  ________           _________  ________  ________  ___       _______      
##     |\  \|\   __  \|\  \|\   ___  \        |\___   ___\\   __  \|\   __  \|\  \     |\  ___ \     
##     \ \  \ \  \|\  \ \  \ \  \\ \  \       \|___ \  \_\ \  \|\  \ \  \|\ /\ \  \    \ \   __/|    
##   __ \ \  \ \  \\\  \ \  \ \  \\ \  \           \ \  \ \ \   __  \ \   __  \ \  \    \ \  \_|/__  
##  |\  \\_\  \ \  \\\  \ \  \ \  \\ \  \           \ \  \ \ \  \ \  \ \  \|\  \ \  \____\ \  \_|\ \ 
##  \ \________\ \_______\ \__\ \__\\ \__\           \ \__\ \ \__\ \__\ \_______\ \_______\ \_______\
##   \|________|\|_______|\|__|\|__| \|__|            \|__|  \|__|\|__|\|_______|\|_______|\|_______|
## --                                  
## RPECK 17/06/2026 - Products Product Media Join Table
## Defines the HABTM relation linking products to sync'd shopify media assets.
################################################################
################################################################

# = Shopify Product Tags Association Join Table Provisioner
#
# Generates the relational bridge layout table mapping core products to their
# respective synchronized tags in a many-to-many topology.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:products_product_tags+
#
class CreateXEngineShopifyProductsProductsTagsJoinTable < XEngine::Core::Database::Migration

  # Enforce structural namespacing parameters for the join table layout target
  set_resource :shopify, :products_product_tags

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Force id: false to eliminate standard auto-incrementing / UUID primary key blocks
    localized_options = table_options.merge(id: false)

    create_table table_name, **localized_options do |t|
      # 1. Foreign key pointing to the primary Product table
      # CRITICAL FIX: Cast to :bigint to match the Shopify numeric GID primary key
      t.references :product, 
                   type: :bigint, 
                   null: false, 
                   foreign_key: { to_table: product_table, on_delete: :cascade }

      # 2. Foreign key pointing to the Product Tag table
      t.references :product_tag, 
                   type: :uuid, 
                   null: false, 
                   foreign_key: { to_table: tag_table, on_delete: :cascade }

      # 3. Composite index optimizing fast bidirectional lookups
      t.index [:product_id, :product_tag_id], 
              name: "idx_xe_shopify_prod_tags_assoc", 
              unique: true
    end
  end

  private

  # Resolves the fully namespaced physical table string value for the Product resource.
  # @return [String]
  def product_table
    XEngine::Core::Model.table_name_for(:shopify, :product)
  end

  # Resolves the fully namespaced physical table string value for the Tag resource.
  # @return [String]
  def tag_table
    XEngine::Core::Model.table_name_for(:shopify, :tag)
  end

end
# :startdoc: