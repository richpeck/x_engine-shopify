# :stopdoc:
################################################################
################################################################
##  ___       ___  ________   _______           ___  _________  _______   _____ ______      
## |\  \     |\  \|\   ___  \|\  ___ \         |\  \|\___   ___\\  ___ \ |\   _ \  _   \    
## \ \  \    \ \  \ \  \\ \  \ \   __/|        \ \  \|___ \  \_\ \   __/|\ \  \\\__\ \  \   
##  \ \  \    \ \  \ \  \\ \  \ \  \_|/__       \ \  \   \ \  \ \ \  \_|/_\ \  \\|__| \  \  
##   \ \  \____\ \  \ \  \\ \  \ \  \_|\ \       \ \  \   \ \  \ \ \  \_|\ \ \  \    \ \  \ 
##    \ \_______\ \__\ \__\\ \__\ \_______\       \ \__\   \ \__\ \ \_______\ \__\    \ \__\
##     \|_______|\|__|\|__| \|__|\|_______|        \|__|    \|__|  \|_______|\|__|     \|__|  
##                                                                               
##  --
##  RPECK 24/06/2026 - Create Shopify Line Items Migration
##  Defines the schema for individual purchased product line metrics within XEngine.
################################################################
################################################################

# = Create Shopify Line Items Database Provisioner
#
# Generates the foundational transaction table schema to log variant breakdowns, quantities, SKUs,
# and specialized country of origin data blocks to sustain corporate accounting audits.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:line_item+
#
# == Schema Layout Matrix
# [+order_id+]           The foreign reference link to the specific parent order transaction.
# [+product_id+]         The unconstrained reference ID for the product attached to the line item.
# [+product_variant_id+] The unconstrained reference ID for the variant attached to the line item.
# [+title+]              The descriptive text representation name of the line row item.
# [+country_of_origin+]  Two-character ISO code tracking structural asset provenance fields.
# [+quantity+]           Integer tracking volume levels purchased inside the line allocation.
#
class CreateXEngineShopifyLineItems < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :line_item

  # Executes schema generation transformations on the target database engine layer.
  #
  # === Returns
  # * +void+
  #
  def up
    create_table table_name, **table_options do |t|

      # Strict relationship bindings to parent order record
      t.belongs_to :order,
                   type: :uuid,
                   foreign_key: { to_table: order_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Loose associations to bypass constraints when remote records don't match local database timeline boundaries
      t.belongs_to :product, type: :bigint, index: true, foreign_key: false
      t.belongs_to :product_variant, type: :bigint, index: true, foreign_key: false

      # String & Ingress Descriptors
      t.string  :title
      t.string  :country_of_origin, limit: 2
      t.integer :quantity

      # Precision Financial Metrics (10, 2 Scales)
      t.decimal :cost_price,     precision: 10, scale: 2
      t.decimal :unit_price,     precision: 10, scale: 2, null: false, default: 0.00
      t.decimal :subtotal,       precision: 10, scale: 2, null: false, default: 0.00
      t.decimal :discount_value, precision: 10, scale: 2, null: false, default: 0.00
      t.decimal :total_received, precision: 10, scale: 2

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