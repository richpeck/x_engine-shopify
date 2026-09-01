# :stopdoc:
################################################################
################################################################
##  ________  _______   ________ ___  ___  ________   ________  
## |\   __  \|\  ___ \ |\  _____\\  \|\  \|\   ___  \|\   ___ \ 
## \ \  \|\  \ \   __/|\ \  \__/\ \  \\\  \ \  \\ \  \ \  \_|\ \
##  \ \   _  _\ \  \_|/_\ \   __\\ \  \\\  \ \  \\ \  \ \  \ \\ \
##   \ \  \\  \\ \  \_|\ \ \  \_| \ \  \\\  \ \  \\ \  \ \  \_\\ \
##    \ \__\\ _\\ \_______\ \__\   \ \_______\ \__\\ \__\ \_______\
##     \|__|\|__| \|_______|\|__|    \|_______|\|__| \|__|\|_______|
##                                                                  
##  --
##  RPECK 24/06/2026 - Create Shopify Refunds Migration
##  Defines the schema for financial order rollbacks within XEngine.
################################################################
################################################################

# frozen_string_literal: true

# = Create Shopify Refunds Database Provisioner
#
# Implements the structural physical data layout for tracking financial order 
# rollbacks mapped down from the external Shopify platform environment (+XEngine::Shopify::Refund+).
#
# == Schema Layout Matrix
# [order_id]   The foreign reference link binding the transaction rollback to its parent order record.
# [note]       Text area capturing the operational reason given for the financial reversion.
# [value]      The precision-bound monetary decimal value returned to the customer.
# [created_at] Standard ActiveRecord timestamp.
# [updated_at] Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyRefunds < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|

      # Establish explicit internal relation binding to the parent transaction record
      t.belongs_to :order,
                   type: :bigint,
                   foreign_key: { to_table: order_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Core Ledger Metrics
      t.text    :note
      t.decimal :value, precision: 10, scale: 2, default: 0.00, null: false

      t.timestamps
    end
  end

  private

  # Resolves the database target table directly from the Refund model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::Refund.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Order+ resource.
  #
  # @return [String]
  def order_table
    @order_table ||= XEngine::Shopify::Order.table_name
  end

end