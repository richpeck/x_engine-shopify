# :stopdoc:
################################################################
################################################################
##    ___      ___ ________  ________  ___  ________  ________   _________        ________  ________  _________  ___  ________  ________          
##   |\  \    /  /|\   __  \|\   __  \|\  \|\   __  \|\   ___  \|\___   ___\     |\   __  \|\   __  \|\___   ___\\  \|\   __  \|\   ___  \        
##   \ \  \  /  / | \  \|\  \ \  \|\  \ \  \ \  \|\  \ \  \\ \  \|___ \  \_|     \ \  \|\  \ \  \|\  \|___ \  \_\ \  \ \  \|\  \ \  \\ \  \       
##    \ \  \/  / / \ \   __  \ \   _  _\ \  \ \   __  \ \  \\ \  \   \ \  \       \ \  \\\  \ \   ____\   \ \  \ \ \  \ \  \\\  \ \  \\ \  \      
##     \ \    / /   \ \  \ \  \ \  \\  \\ \  \ \  \ \  \ \  \\ \  \   \ \  \       \ \  \\\  \ \  \___|    \ \  \ \ \  \ \  \\\  \ \  \\ \  \     
##      \ \__/ /     \ \__\ \__\ \__\\ _\\ \__\ \__\ \__\ \__\\ \__\   \ \__\       \ \_______\ \__\        \ \__\ \ \__\ \_______\ \__\\ \__\    
##       \|__|/       \|__|\|__|\|__|\|__|\|__|\|__|\|__|\|__| \|__|    \|__|        \|_______|\|__|         \|__|  \|__|\|_______|\|__| \|__|    
##  --                                                                                                                                             
##  RPECK 22/08/2026 - Create Shopify Variant Options Migration
##  Defines the join table schema connecting individual product variants to product options.
################################################################
################################################################

# frozen_string_literal: true

# = Create Shopify Variant Options Database Provisioner
#
# Generates the physical join relation table connecting product variant models to their corresponding 
# product option definitions and option choices (+XEngine::Shopify::VariantOption+).
#
# == Schema Layout Matrix
# [product_variant_id] Foreign reference binding to the parent product variant model.
# [product_option_id]  Foreign reference binding to the product option metadata model.
# [shop_id]            Optional foreign reference binding to the owner shop context.
# [value]              The actual value assigned to this option selection (e.g., "Red", "Large").
# [created_at]         Standard ActiveRecord timestamp.
# [updated_at]         Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyVariantOptions < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    create_table table_name, **table_options do |t|

      # Foreign key binding to the parent product variant
      t.belongs_to :product_variant,
                   type: :bigint,
                   foreign_key: { to_table: product_variant_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Foreign key binding to the parent product option
      t.belongs_to :product_option,
                   type: :bigint,
                   foreign_key: { to_table: product_option_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Optional foreign key binding to the shop context
      t.belongs_to :shop,
                   type: :uuid,
                   foreign_key: { to_table: shop_table, on_delete: :nullify },
                   null: true,
                   index: true

      # The string value of the variant option selection
      t.string :value, null: false

      t.timestamps
    end

    # Compound unique index ensuring a variant cannot have duplicate entries for the same option
    add_index table_name, [:product_variant_id, :product_option_id], 
              unique: true, 
              name: 'idx_shopify_variant_options_uniqueness'

    # Compound index for lookup filtering on specific option values across variants
    add_index table_name, [:product_option_id, :value]
  end

  private

  # Resolves the database target table directly from the VariantOption model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::VariantOption.table_name
  end

  # Resolves the physical table string value for the companion ProductVariant resource.
  #
  # @return [String]
  def product_variant_table
    @product_variant_table ||= XEngine::Shopify::ProductVariant.table_name
  end

  # Resolves the physical table string value for the companion ProductOption resource.
  #
  # @return [String]
  def product_option_table
    @product_option_table ||= XEngine::Shopify::ProductOption.table_name
  end

  # Resolves the physical table string value for the companion Shop resource.
  #
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

end