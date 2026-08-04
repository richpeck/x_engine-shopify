# :stopdoc:
################################################################
################################################################
##  ________  _______   ________ ___  ___  ________   ________          ___       ___  ________   _______           ___  _________  _______   _____ ______          
## |\   __  \|\  ___ \ |\  _____\\  \|\  \|\   ___  \|\   ___ \        |\  \     |\  \|\   ___  \|\  ___ \         |\  \|\___   ___\\  ___ \ |\   _ \  _   \        
## \ \  \|\  \ \   __/|\ \  \__/\ \  \\\  \ \  \\ \  \ \  \_|\ \       \ \  \    \ \  \ \  \\ \  \ \   __/|        \ \  \|___ \  \_\ \   __/|\ \  \\\__\ \  \       
##  \ \   _  _\ \  \_|/_\ \   __\\ \  \\\  \ \  \\ \  \ \  \ \\ \       \ \  \    \ \  \ \  \\ \  \ \  \_|/__       \ \  \   \ \  \ \ \  \_|/_\ \  \\|__| \  \      
##   \ \  \\  \\ \  \_|\ \ \  \_| \ \  \\\  \ \  \\ \  \ \  \_\\ \       \ \  \____\ \  \ \  \\ \  \ \  \_|\ \       \ \  \   \ \  \ \ \  \_|\ \ \  \    \ \  \     
##    \ \__\\ _\\ \_______\ \__\   \ \_______\ \__\\ \__\ \_______\       \ \_______\ \__\ \__\\ \__\ \_______\       \ \__\   \ \__\ \ \_______\ \__\    \ \__\    
##     \|__|\|__|\|_______|\|__|    \|_______|\|__| \|__|\|_______|        \|_______|\|__|\|__| \|__|\|_______|        \|__|    \|__|  \|_______|\|__|     \|__|           
##                                                                                                                                                 
##  --
##  RPECK 24/06/2026 - Create Shopify Refund Line Items Migration
##  Defines the schema for linking refunded products back to transaction rollbacks within XEngine.
################################################################
################################################################

# frozen_string_literal: true

# = Create Shopify Refund Line Items Database Provisioner
#
# Generates the physical relation map table used to inventory refunded items, quantity steps,
# and dynamically modified pricing parameters (+XEngine::Shopify::RefundLineItem+).
#
# == Schema Layout Matrix
# [refund_id]    The foreign reference link to the specific parent refund transaction.
# [line_item_id] The foreign reference link pointing to the original order line item entry.
# [quantity]     The specific count footprint of products returned under this specific line.
# [subtotal]     Decimal column tracking unit cost to guarantee granular VAT recalculation structures.
# [created_at]   Standard ActiveRecord timestamp.
# [updated_at]   Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyRefundLineItems < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    create_table table_name, **table_options do |t|

      # Strict relationship bindings to parent records
      t.belongs_to :refund,
                   type: :uuid,
                   foreign_key: { to_table: refund_table, on_delete: :cascade },
                   null: false,
                   index: true

      t.belongs_to :line_item,
                   type: :uuid,
                   foreign_key: { to_table: line_item_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Line Quantities & Reverted Monetary Volumes
      t.integer :quantity, null: false, default: 0
      t.decimal :subtotal, precision: 10, scale: 2, default: 0.00, null: false

      t.timestamps
    end
  end

  private

  # Resolves the database target table directly from the RefundLineItem model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::RefundLineItem.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Refund+ resource.
  #
  # @return [String]
  def refund_table
    @refund_table ||= XEngine::Shopify::Refund.table_name
  end

  # Resolves the fully namespaced physical table string value for the companion +LineItem+ resource.
  #
  # @return [String]
  def line_item_table
    @line_item_table ||= XEngine::Shopify::LineItem.table_name
  end

end