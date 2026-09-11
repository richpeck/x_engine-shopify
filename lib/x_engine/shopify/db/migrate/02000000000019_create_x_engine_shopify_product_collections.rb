# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  ________  ___  ___  ________ _________        ________  ________  ___       ___       _______   ________ _________  ___  ________  ________      
##  |\   __  \|\   __  \|\   __  \|\   ___ \|\  \|\  \|\   ____\\___   ___\     |\   ____\|\   __  \|\  \     |\  \     |\  ___ \ |\   ____\\___   ___\\  \|\   __  \|\   ___  \    
##  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \___\|___ \  \_|     \ \  \___|\ \  \|\  \ \  \    \ \  \    \ \   __/|\ \  \___\|___ \  \_\ \  \ \  \|\  \ \  \\ \  \   
##   \ \   ____\ \   _  _\ \  \\\  \ \  \ \\ \ \  \\\  \ \  \       \ \  \       \ \  \    \ \  \\\  \ \  \    \ \  \    \ \  \_|/_\ \  \       \ \  \ \ \  \ \  \\\  \ \  \\ \  \  
##    \ \  \___|\ \  \\  \\ \  \\\  \ \  \_\\ \ \  \\\  \ \  \____   \ \  \       \ \  \____\ \  \\\  \ \  \____\ \  \____\ \  \_|\ \ \  \____   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ 
##     \ \__\    \ \__\\ _\\ \_______\ \_______\ \_______\ \_______\  \ \__\       \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\  \ \__\ \ \__\ \_______\ \__\\ \__\
##      \|__|     \|__|\|__|\|_______|\|_______|\|_______|\|_______|   \|__|        \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|   \|__|  \|__|\|_______|\|__| \|__|                                      
## --
##  RPECK 11/02/2024 - ProductCollection Option object
##  Acts as join model between Product and Collection
################################################################
################################################################

# frozen_string_literal: true

# = Create Shopify Product Collections Database Provisioner
#
# Generates the physical join relation table connecting product models to their corresponding 
# collection definitions (+XEngine::Shopify::ProductCollection+).
#
# == Schema Layout Matrix
# [product_id]    Foreign reference binding to the product model.
# [collection_id] Foreign reference binding to the collection model.
# [shop_id]       Optional foreign reference binding to the owner shop context.
# [position]     Optional position/order integer for product placement within the collection.
# [created_at]    Standard ActiveRecord timestamp.
# [updated_at]    Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyProductCollections < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    create_table table_name, **table_options do |t|

      # Foreign key binding to the parent product
      t.belongs_to :product,
                   type: :bigint,
                   foreign_key: { to_table: product_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Foreign key binding to the parent collection
      t.belongs_to :collection,
                   type: :bigint,
                   foreign_key: { to_table: collection_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Optional foreign key binding to the shop context
      t.belongs_to :shop,
                   type: :uuid,
                   foreign_key: { to_table: shop_table, on_delete: :nullify },
                   null: true,
                   index: true

      # Product display ordering within the collection
      t.integer :position, null: true

      t.timestamps
    end

    # Compound unique index ensuring a product cannot have duplicate entries in the same collection
    add_index table_name, [:collection_id, :product_id], 
              unique: true, 
              name: 'idx_shopify_product_collections_uniqueness'

    # Compound index for fast collection position lookups
    add_index table_name, [:collection_id, :position]
  end

  private

  # Resolves the database target table directly from the ProductCollection model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::ProductCollection.table_name
  end

  # Resolves the physical table string value for the companion Product resource.
  #
  # @return [String]
  def product_table
    @product_table ||= XEngine::Shopify::Product.table_name
  end

  # Resolves the physical table string value for the companion Collection resource.
  #
  # @return [String]
  def collection_table
    @collection_table ||= XEngine::Shopify::Collection.table_name
  end

  # Resolves the physical table string value for the companion Shop resource.
  #
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

end