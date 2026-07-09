# :stopdoc:
################################################################
################################################################
##   ________ ___  ___  ___       ________ ___  ___       ___       _____ ______   _______   ________   _________  ________      
##  |\  _____\\  \|\  \|\  \     |\  _____\\  \|\  \     |\  \     |\   _ \  _   \|\  ___ \ |\   ___  \|\___   ___\\   ____\     
##  \ \  \__/\ \  \\\  \ \  \    \ \  \__/\ \  \ \  \    \ \  \    \ \  \\\__\ \  \ \   __/|\ \  \\ \  \|___ \  \_\ \  \___|_    
##   \ \   __\\ \  \\\  \ \  \    \ \   __\\ \  \ \  \    \ \  \    \ \  \\|__| \  \ \  \_|/_\ \  \\ \  \   \ \  \ \ \_____  \   
##    \ \  \_| \ \  \\\  \ \  \____\ \  \_| \ \  \ \  \____\ \  \____\ \  \    \ \  \ \  \_|\ \ \  \\ \  \   \ \  \ \|____|\  \  
##     \ \__\   \ \_______\ \_______\ \__\   \ \__\ \_______\ \_______\ \__\    \ \__\ \_______\ \__\\ \__\   \ \__\  ____\_\  \ 
##      \|__|    \|_______|\|_______|\|__|    \|__|\|_______|\|_______|\|__|     \|__|\|_______|\|__| \|__|    \|__| |\_________\
##                                                                                                                    \|_________|                                                                                                                                      
##  --
##  RPECK 24/06/2026 - Create Shopify Refund Line Items Migration
##  Defines the schema for linking refunded products back to transaction rollbacks within XEngine.
################################################################
################################################################

# = Create Shopify Fulfillments Database Provisioner
#
# Generates the physical relation map table used to inventory tracking milestones,
# fulfillment state flags, and delivery courier references.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:fulfillment+
#
class CreateXEngineShopifyFulfillments < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :fulfillment

  # Executes schema generation transformations on the target database engine layer.
  def up
    create_table table_name, **table_options do |t|

      # Strict relationship binding to the parent order record
      t.belongs_to :order,
                   type: :uuid,
                   foreign_key: { to_table: order_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Operational and Tracking Metrics
      t.string :name
      t.string :status
      t.string :tracking_company
      
      # Text blocks to cleanly handle split or serialized delivery tracking pointers
      t.text :tracking_numbers
      t.text :tracking_urls

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