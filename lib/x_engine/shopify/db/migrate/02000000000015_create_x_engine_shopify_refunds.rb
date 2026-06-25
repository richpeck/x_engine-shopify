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

# = Create Shopify Refunds Database Provisioner
#
# Implements the structural physical data layout for tracking financial order 
# rollbacks mapped down from the external Shopify platform environment.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:refund+
#
# == Schema Layout Matrix
# [+order_id+]  The foreign reference link binding the transaction rollback to its parent order record.
# [+note+]      Text area capturing the operational reason given for the financial reversion.
# [+value+]     The precision-bound monetary decimal value returned to the customer.
#
class CreateXEngineShopifyRefunds < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :refund

  # Executes schema generation transformations on the target database engine layer.
  #
  # === Returns
  # * +void+
  #
  def up
    create_table table_name, **table_options do |t|

      # Establish explicit internal relation binding to the parent transaction record
      t.belongs_to :order,
                   type: :uuid,
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

  # Resolves the fully namespaced physical table string value for the parent +Order+ resource.
  #
  # === Returns
  # * +String+:: The exact calculated table string target (e.g., +"x_engine_shopify_orders"+).
  #
  def order_table
    XEngine::Core::Model.table_name_for(:shopify, :order)
  end

end
# :startdoc: