# :stopdoc:
################################################################
################################################################
##   ________  ________  _________  ___  ________  ________   
##  |\   __  \|\   __  \|\___   ___\\  \|\   __  \|\   ___  \  
##  \ \  \|\  \ \  \|\  \|___ \  \_\ \  \ \  \|\  \ \  \\ \  \ 
##   \ \  \\\  \ \   ____\   \ \  \ \ \  \ \  \\\  \ \  \\ \  \
##    \ \  \\\  \ \  \___|    \ \  \ \ \  \ \  \\\  \ \  \\ \  \
##     \ \_______\ \__\        \ \__\ \ \__\ \_______\ \__\\ \__\
##      \|_______|\|__|         \|__|  \|__|\|_______|\|__| \|__|
##                                                              
## --
##  RPECK 09/07/2026 - Create Shopify Product Options Migration
##  Defines the schema for recording variant matrix option keys, positions, and display metadata.
################################################################
################################################################

# frozen_string_literal: true

# = Create Shopify Product Options Database Provisioner
#
# Generates the physical relation map table used to inventory product variant options,
# display positioning metrics, and option labels (+XEngine::Shopify::ProductOption+).
#
# == Schema Layout Matrix
# [product_id]     The foreign reference link to the parent product model.
# [shop_id]        The optional foreign reference link to the owner shop context.
# [shopify_id]     The raw platform identifier returned from the Shopify GraphQL API.
# [name]           The attribute label for the option matrix (e.g., Size, Color).
# [position]       Integer index position for UI ordering and payload alignment.
# [created_at]     Standard ActiveRecord timestamp.
# [updated_at]     Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyProductOptions < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|

      # Strict relationship binding to the parent product record
      t.belongs_to :product,
                   type: :bigint,
                   foreign_key: { to_table: product_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Optional relationship binding to the shop context
      t.belongs_to :shop,
                   type: :uuid,
                   foreign_key: { to_table: shop_table, on_delete: :nullify },
                   null: true,
                   index: true

      # Platform identifier
      t.string :shopify_id, null: false

      # Option Attributes & Display Positioning
      t.string  :name,     null: false
      t.integer :position, null: false, default: 1

      t.timestamps
    end

    # Compound unique index for shopify_id scoped to shop context
    add_index table_name, [:shopify_id, :shop_id], unique: true

    # Compound index for position sorting lookups within product context
    add_index table_name, [:product_id, :position]
  end

  private

  # Resolves the database target table directly from the ProductOption model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::ProductOption.table_name
  end

  # Resolves the fully namespaced physical table string value for the companion Product resource.
  #
  # @return [String]
  def product_table
    @product_table ||= XEngine::Shopify::Product.table_name
  end

  # Resolves the fully namespaced physical table string value for the companion Shop resource.
  #
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

end