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
# Generates the target schema required to persist direct string tag assignments attached
# to individual shopify products (+XEngine::Shopify::ProductTag+).
#
# == Schema Layout Matrix
# [id]          System-managed unique primary key handling distributed lookups safely using a native +UUID+ format.
# [product_id]  The reference link mapping the owner product model. Enforces cascading delete on product teardown.
# [name]        The plain string token value representing the tag identity (e.g., <tt>"Summer-Collection"</tt>).
# [created_at]  Standard ActiveRecord timestamp.
# [updated_at]  Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyProductTags < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|
      t.belongs_to :product, type: :bigint, foreign_key: { to_table: product_table, on_delete: :cascade }, null: false

      t.string :name, null: false

      t.timestamps

      # Compound index enforcing tag uniqueness per product and optimizing product lookup
      t.index [:product_id, :name], unique: true, name: "idx_xe_shopify_prod_tags_unique"

      # High-speed reverse index for filtering products by tag name
      t.index [:name, :product_id], name: "idx_xe_shopify_prod_tags_lookup"
    end
  end

  private

  # Resolves the database target table directly from the ProductTag model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::ProductTag.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Product+ resource.
  #
  # @return [String]
  def product_table
    @product_table ||= XEngine::Shopify::Product.table_name
  end

end