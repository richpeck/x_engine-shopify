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

# frozen_string_literal: true

# = Create Shopify Orders Database Provisioner
#
# Generates the physical structure for recording core order objects, transaction values,
# fulfillment checkpoints, and compound scope constraints received from the platform gateway (+XEngine::Shopify::Order+).
#
# == Schema Layout Matrix
# [shop_id]               The foreign reference link to the owner shop profile.
# [shopify_id]            The platform global identifier (GID or numeric ID string).
# [name]                  The descriptive or numeric platform order identity token (e.g., "#1001").
# [payment_gateways]      Payment gateway identifiers used for the order.
# [currency]              Three-letter currency code for order monetary values.
# [shipping_country]      Two-character ISO code mapping the customer delivery destination context.
# [financial_status]      Financial payment state of the order.
# [fulfillment_status]    Fulfillment processing state of the order.
# [line_items_count]      Cached counter for line items attached to the order.
# [refunded_items_count]  Cached counter for refunded items.
# [subtotal]              Subtotal monetary value of the order.
# [total_shipping]        Shipping cost monetary value.
# [total_tax]             Tax monetary value.
# [total_order_value]     Gross transactional baseline volume tracking.
# [total_refunded_amount] Total monetary amount refunded.
# [total_received]        Net processing metric recording actual financial capture sweeps.
# [created_at]            Standard ActiveRecord timestamp.
# [updated_at]            Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyOrders < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|

      # Strict relationship bindings to parent shop record
      t.belongs_to :shop,
                   type: :uuid,
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
      t.decimal :subtotal,             precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_shipping,       precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_tax,            precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_order_value,    precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_refunded_amount, precision: 10, scale: 2, default: 0.00, null: false
      t.decimal :total_received,       precision: 10, scale: 2, default: 0.00, null: false

      t.timestamps

      # Compound Scope Constraints & Indices for BulkUpsert
      t.index [:shop_id, :name],       unique: true, name: "idx_x_engine_shopify_orders_on_shop_and_name"
    end
  end

  private

  # Resolves the database target table directly from the Order model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::Order.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  #
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

end