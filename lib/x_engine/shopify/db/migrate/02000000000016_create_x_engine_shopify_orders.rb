# :stopdoc:
################################################################
################################################################
##  ________  ________  ________  _______   ________        
## |\   __  \|\   __  \|\   ___ \|\  ___ \ |\   __  \       
## \ \  \|\  \ \  \|\  \ \  \_|\ \ \   __/|\ \  \|\  \      
##  \ \  \\\  \ \   _  _\ \  \ \\ \ \  \_|/_\ \   _  _\     
##   \ \  \\\  \ \  \\  \\ \  \_\\ \ \  \_|\ \ \  \\  \|    
##    \ \_______\ \__\\ _\\ \_______\ \_______\ \__\\ _\    
##     \|_______|\|__|\|__|\|_______|\|_______|\|__|\|__|    
##                                                                  
##  --
##  RPECK 24/06/2026 - Create Shopify Orders Migration
##  Defines the schema for core sales order tracking and transaction telemetry within XEngine.
################################################################
################################################################

# = Create Shopify Orders Database Provisioner
#
# Generates the physical structure for recording core order objects, transaction values,
# fulfillment checkpoints, and compound scope constraints received from the platform gateway.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:order+
#
# == Schema Layout Matrix
# [+shop_id+]               The foreign reference link to the owner shop profile.
# [+name+]                  The descriptive or numeric platform order identity token (e.g., "#1001").
# [+shipping_country+]      Two-character ISO code mapping the customer delivery destination context.
# [+total_order_value+]     Gross transactional baseline volume tracking.
# [+total_received+]        Net processing metric recording actual financial capture sweeps.
#
class CreateXEngineShopifyOrders < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :order

  # Executes schema generation transformations on the target database engine layer.
  #
  # === Returns
  # * +void+
  #
  def up
    create_table table_name, **table_options do |t|

      # Strict relationship bindings to parent shop record
      t.belongs_to :shop,
                   type: :bigint,
                   foreign_key: { to_table: shop_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Platform Strings & Context Fields
      t.string :name
      t.string :payment_gateways
      t.string :currency
      t.string :shipping_country, limit: 2
      t.string :financial_status
      t.string :fulfillment_status, default: "unfulfilled", null: false

      # Operational Ingress Counters
      t.integer :line_items_count
      t.integer :refunded_items_count, default: 0, null: false

      # Precision Financial Metrics (10, 2 Scales)
      t.decimal :subtotal,              precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_shipping,        precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_tax,             precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_order_value,     precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_refunded_amount, precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_received,        precision: 10, scale: 2, default: 0.00, null: false

      t.timestamps

      # Guarantee unique order name allocations scoped strictly per tenant shop resource
      t.index [:shop_id, :name], unique: true, name: "idx_x_engine_shopify_orders_on_shop_and_name"
    end
  end

  private

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  #
  # === Returns
  # * +String+:: The exact calculated table string target (e.g., +"x_engine_shopify_shops"+).
  #
  def shop_table
    XEngine::Core::Model.table_name_for(:shopify, :shop)
  end

end
# :startdoc: