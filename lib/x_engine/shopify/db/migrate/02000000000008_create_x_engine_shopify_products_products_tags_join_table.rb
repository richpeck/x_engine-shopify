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

# frozen_string_literal: true

# = Shopify Product Tags Association Join Table Provisioner
#
# Generates the relational bridge layout table mapping core products to their
# respective synchronized tags in a many-to-many topology (+XEngine::Shopify::ProductsProductTag+).
#
# == Schema Layout Matrix
# [product_id]     Foreign key reference pointing to the primary Product table (bigint).
# [product_tag_id] Foreign key reference pointing to the Product Tag table (uuid).
#
class CreateXEngineShopifyProductsProductsTagsJoinTable < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    create_table table_name, **table_options do |t|
      # 1. Foreign key pointing to the primary Product table
      t.references :product, 
                   type: :bigint, 
                   null: false, 
                   foreign_key: { to_table: product_table, on_delete: :cascade }

      # 2. Foreign key pointing to the Product Tag table
      t.references :tag, 
                   type: :uuid, 
                   null: false, 
                   foreign_key: { to_table: tag_table, on_delete: :cascade }

      # 3. Composite index optimizing fast bidirectional lookups
      t.index [:product_id, :tag_id], 
              name: "idx_xe_shopify_prod_tags_assoc", 
              unique: true
    end
  end

  private

  # Resolves the database target table directly from the model class or fallback convention.
  #
  # @return [String]
  def table_name
    @table_name ||= :shopify_products_tags
  end

  # Resolves the fully namespaced physical table string value for the Product resource.
  #
  # @return [String]
  def product_table
    @product_table ||= XEngine::Shopify::Product.table_name
  end

  # Resolves the fully namespaced physical table string value for the Tag resource.
  #
  # @return [String]
  def tag_table
    @tag_table ||= XEngine::Shopify::Tag.table_name
  end

end