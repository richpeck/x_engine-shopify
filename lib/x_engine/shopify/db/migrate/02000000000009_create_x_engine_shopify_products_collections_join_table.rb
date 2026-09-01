# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  ________  ___  ___  ________ _________        ________  ________  ___       ___       _______   ________ _________  ___  ________  ________   ________      
##  |\   __  \|\   __  \|\   __  \|\   ___ \|\  \|\  \|\   ____\\___   ___\     |\   ____\|\   __  \|\  \     |\  \     |\  ___ \ |\   ____\\___   ___\\  \|\   __  \|\   ___  \|\   ____\     
##  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \___\|___ \  \_|     \ \  \___|\ \  \|\  \ \  \    \ \  \    \ \   __/|\ \  \___\|___ \  \_\ \  \ \  \|\  \ \  \\ \  \ \  \___|_    
##   \ \   ____\ \   _  _\ \  \\\  \ \  \ \\ \ \  \\\  \ \  \       \ \  \       \ \  \    \ \  \\\  \ \  \    \ \  \    \ \  \_|/_\ \  \       \ \  \ \ \  \ \  \\\  \ \  \\ \  \ \_____  \   
##    \ \  \___|\ \  \\  \\ \  \\\  \ \  \_\\ \ \  \\\  \ \  \____   \ \  \       \ \  \____\ \  \\\  \ \  \____\ \  \____\ \  \_|\ \ \  \____   \ \  \ \ \  \ \  \\\  \ \  \\ \  \|____|\  \  
##     \ \__\    \ \__\\ _\\ \_______\ \_______\ \_______\ \_______\  \ \__\       \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\  \ \__\ \ \__\ \_______\ \__\\ \__\____\_\  \ 
##      \|__|     \|__|\|__|\|_______|\|_______|\|_______|\|_______|   \|__|        \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|   \|__|  \|__|\|_______|\|__| \|__|\_________\
##                                                                                                                                                                                 \|_________|                                                                                         
## --
## RPECK 17/06/2026 - Products Collections Join Table
## Defines the relational HABTM bridge layout table mapping products to collections within XEngine.
################################################################
################################################################

# frozen_string_literal: true

# = Shopify Products Collections Association Join Table Provisioner
#
# Generates the relational bridge table mapping shopify product models to their
# respective collections in a multi-tenant many-to-many lookup topology (+XEngine::Shopify::ProductsCollection+).
#
# == Schema Layout Matrix
# [product_id]    Foreign key reference pointing to the parent Product. Constrained to <tt>bigint</tt> to match Shopify's naked ID strategy.
# [collection_id] Foreign key reference pointing to the parent Collection. Constrained to <tt>bigint</tt> to match Shopify's naked ID strategy.
#
class CreateXEngineShopifyProductsCollectionsJoinTable < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    create_table table_name, **table_options do |t|
      
      # 1. Foreign key pointing to the Product table (CRITICAL: Must be :bigint to match Shopify's naked ID)
      t.references :product,
                   type: :bigint,
                   null: false,
                   foreign_key: { to_table: product_table, on_delete: :cascade }

      # 2. Foreign key pointing to the Collection table (CRITICAL: Must be :bigint to match Shopify's naked ID)
      t.references :collection,
                   type: :bigint,
                   null: false,
                   foreign_key: { to_table: collection_table, on_delete: :cascade }

      # 3. Composite index optimizing fast bidirectional filtering lookups
      t.index [:product_id, :collection_id],
              name: "idx_xe_shopify_prod_colls_poly",
              unique: true

    end
  end

  private

  # Resolves the database target table directly from the model class or fallback convention.
  #
  # @return [String]
  def table_name
    @table_name ||= :shopify_collections_products
  end

  # Resolves the fully namespaced physical table string value for the Product resource.
  #
  # @return [String]
  def product_table
    @product_table ||= XEngine::Shopify::Product.table_name
  end

  # Resolves the fully namespaced physical table string value for the Collection resource.
  #
  # @return [String]
  def collection_table
    @collection_table ||= XEngine::Shopify::Collection.table_name
  end

end