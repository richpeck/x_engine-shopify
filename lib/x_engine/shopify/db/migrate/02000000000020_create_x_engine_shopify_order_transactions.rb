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

# = Create Shopify Order Transactions Database Provisioner
#
# Generates the physical relation map table used to inventory transaction processing rounds,
# gateway tracking references, processing fees, and financial settlement states.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:order_transaction+
#
class CreateXEngineShopifyOrderTransactions < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :order_transaction

  # Executes schema generation transformations on the target database engine layer.
  def up
    create_table table_name, **table_options do |t|

      # Strict relationship binding to the parent order record
      t.belongs_to :order,
                   type: :uuid,
                   foreign_key: { to_table: order_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Processing Context & Gateway Mappings
      t.string :kind
      t.string :status
      t.string :gateway
      t.string :transaction_id

      # Financial Values
      t.decimal :amount, precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :fee,    precision: 10, scale: 2, default: 0.00, null: false

      t.timestamps
    end
  end

  private

  # Resolves the fully namespaced physical table string value for the companion Order resource.
  def order_table
    XEngine::Core::Model.table_name_for(:shopify, :order)
  end

end
# :startdoc: