# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  _______   ________          _________  ________  ________  ________   ________  ________  ________ _________  ___  ________  ________      
##  |\   __  \|\   __  \|\   ___ \|\  ___ \ |\   __  \        |\___   ___\\   __  \|\   __  \|\   ___  \|\   ____\|\   __  \|\   ____\\___   ___\\  \|\   __  \|\   ___  \    
##  \ \  \|\  \ \  \|\  \ \  \_|\ \ \   __/|\ \  \|\  \       \|___ \  \_\ \  \|\  \ \  \|\  \ \  \\ \  \ \  \___|\ \  \|\  \ \  \___\|___ \  \_\ \  \ \  \|\  \ \  \\ \  \   
##   \ \  \\\  \ \   _  _\ \  \ \\ \ \  \_|/_\ \   _  _\           \ \  \ \ \   _  _\ \   __  \ \  \\ \  \ \_____  \ \   __  \ \  \       \ \  \ \ \  \ \  \\\  \ \  \\ \  \  
##    \ \  \\\  \ \  \\  \\ \  \_\\ \ \  \_|\ \ \  \\  \|           \ \  \ \ \  \\  \\ \  \ \  \ \  \\ \  \|____|\  \ \  \ \  \ \  \____   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ 
##     \ \_______\ \__\\ _\\ \_______\ \_______\ \__\\ _\            \ \__\ \ \__\\ _\\ \__\ \__\ \__\\ \__\____\_\  \ \__\ \__\ \_______\  \ \__\ \ \__\ \_______\ \__\\ \__\
##      \|_______|\|__|\|__|\|_______|\|_______|\|__|\|__|            \|__|  \|__|\|__|\|__|\|__|\|__| \|__|\_________\|__|\|__|\|_______|   \|__|  \|__|\|_______|\|__| \|__|
##                                                                                                         \|_________|                                                              
##                                                                                                                                                 
##  --
##  RPECK 09/07/2026 - Create Shopify Order Transactions Migration
##  Defines the schema for recording transactional audits, gateways, and monetary processing steps.
################################################################
################################################################

# frozen_string_literal: true

# = Create Shopify Order Transactions Database Provisioner
#
# Generates the physical relation map table used to inventory transaction processing rounds,
# gateway tracking references, processing fees, and financial settlement states (+XEngine::Shopify::OrderTransaction+).
#
# == Schema Layout Matrix
# [order_id]       The foreign reference link to the specific parent order transaction.
# [kind]           The type of transaction (e.g., authorization, capture, sale, void, refund).
# [status]         The processing status state of the transaction.
# [gateway]        The payment gateway name used to process the transaction.
# [transaction_id] External gateway transaction identifier token.
# [amount]         Monetary value processed in the transaction.
# [fee]            Gateway processing fee amount.
# [created_at]     Standard ActiveRecord timestamp.
# [updated_at]     Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyOrderTransactions < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    create_table table_name, **table_options do |t|

      # Strict relationship binding to the parent order record
      t.belongs_to :order,
                   type: :bigint,
                   foreign_key: { to_table: order_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Processing Context & Gateway Mappings
      t.string :kind
      t.string :status
      t.string :gateway

      # Financial Values
      t.decimal :amount, precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :fee,    precision: 10, scale: 2, default: 0.00, null: false

      t.timestamps
    end
  end

  private

  # Resolves the database target table directly from the OrderTransaction model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::OrderTransaction.table_name
  end

  # Resolves the fully namespaced physical table string value for the companion Order resource.
  #
  # @return [String]
  def order_table
    @order_table ||= XEngine::Shopify::Order.table_name
  end

end