# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  ________  ___  ___  ________ _________        _________  ________  ________     
##  |\   __  \|\   __  \|\   __  \|\   ___ \|\  \|\  \|\   ____\\___   ___\     |\___   ___\\   __  \|\   ____\    
##  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \___\|___ \  \_|     \|___ \  \_\ \  \|\  \ \  \___|    
##   \ \   ____\ \   _  _\ \  \\\  \ \  \ \\ \ \  \\\  \ \  \       \ \  \           \ \  \ \ \   __  \ \  \  ___  
##    \ \  \___|\ \  \\  \\ \  \\\  \ \  \_\\ \ \  \\\  \ \  \____   \ \  \           \ \  \ \ \  \ \  \ \  \|\  \ 
##     \ \__\    \ \__\\ _\\ \_______\ \_______\ \_______\ \_______\  \ \__\           \ \__\ \ \__\ \__\ \_______\
##      \|__|     \|__|\|__|\|_______|\|_______|\|_______|\|_______|   \|__|            \|__|  \|__|\|__|\|_______|         
##                                                              
## --
## RPECK 17/01/2024 - Product Tags Datatable
## Defines the product-linked schema for storing direct tag assignments within XEngine.
################################################################
################################################################

# frozen_string_literal: true

# = Shopify Product Tag Database Provisioner
#
# Generates the target join schema linking products to their associated tag entities
# (+XEngine::Shopify::ProductTag+).
#
# == Schema Layout Matrix
# [id]         Bigint primary key.
# [product_id] Foreign reference binding to the parent product model. Enforces cascading delete.
# [tag_id]     Foreign reference binding to the normalized tag model. Enforces cascading delete.
# [created_at] Standard ActiveRecord timestamp.
# [updated_at] Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyProductTags < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|
      t.belongs_to :product,
                   type: :bigint,
                   foreign_key: { to_table: product_table, on_delete: :cascade },
                   null: false,
                   index: true

      t.belongs_to :tag,
                   type: :bigint,
                   foreign_key: { to_table: tag_table, on_delete: :cascade },
                   null: false,
                   index: true

      t.timestamps

      # Compound index enforcing tag assignment uniqueness per product
      t.index [:product_id, :tag_id], unique: true, name: "idx_xe_shopify_prod_tags_unique"

      # Reverse compound index for fast lookup of products by tag
      t.index [:tag_id, :product_id], name: "idx_xe_shopify_prod_tags_lookup"
    end
  end

  private

  # Resolves the database target table directly from the ProductTag model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::ProductTag.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent Product resource.
  #
  # @return [String]
  def product_table
    @product_table ||= XEngine::Shopify::Product.table_name
  end

  # Resolves the fully namespaced physical table string value for the companion Tag resource.
  #
  # @return [String]
  def tag_table
    @tag_table ||= XEngine::Shopify::Tag.table_name
  end

end