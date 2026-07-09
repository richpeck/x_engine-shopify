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

# = Create Shopify Refund Line Items Database Provisioner
#
# Generates the physical relation map table used to inventory refunded items, quantity steps,
# and dynamically modified pricing parameters.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:refund_line_item+
#
# == Schema Layout Matrix
# [+refund_id+ ]   The foreign reference link to the specific parent refund transaction.
# [+line_item_id+] The foreign reference link pointing to the original order line item entry.
# [+quantity+    ] The specific count footprint of products returned under this specific line.
# [+subtotal+    ] Decimal column tracking unit cost to guarantee granular VAT recalculation structures.
#
class CreateXEngineShopifyRowLevelSecurity < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :refund_line_item

  # Executes schema generation transformations on the target database engine layer.
  #
  # === Returns
  # * +void+
  #
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

  # Resolves the fully namespaced physical table string value for the parent +Refund+ resource.
  def refund_table
    XEngine::Core::Model.table_name_for(:shopify, :refund)
  end

  # Resolves the fully namespaced physical table string value for the companion +LineItem+ resource.
  def line_item_table
    XEngine::Core::Model.table_name_for(:shopify, :line_item)
  end

end
# :startdoc: