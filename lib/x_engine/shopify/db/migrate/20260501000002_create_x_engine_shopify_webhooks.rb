# :stopdoc:
################################################################
################################################################
##   ___       __   _______   ________  ___  ___  ________  ________  ___  __    ________      
##  |\  \     |\  \|\  ___ \ |\   __  \|\  \|\  \|\   __  \|\   __  \|\  \|\  \ |\   ____\     
##  \ \  \    \ \  \ \   __/|\ \  \|\ /\ \  \\\  \ \  \|\  \ \  \|\  \ \  \/  /|\ \  \___|_    
##   \ \  \  __\ \  \ \  \_|/_\ \   __  \ \   __  \ \  \\\  \ \  \\\  \ \   ___  \ \_____  \   
##    \ \  \|\__\_\  \ \  \_|\ \ \  \|\  \ \  \ \  \ \  \\\  \ \  \\\  \ \  \\ \  \|____|\  \  
##     \ \____________\ \_______\ \_______\ \__\ \__\ \_______\ \_______\ \__\\ \__\____\_\  \ 
##      \|____________|\|_______|\|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|\_________\
##                                                                                 \|_________|
##  --
##  RPECK 23/04/2026 - Shopify Webhooks Migration
##  Defines the schema for Shopify stores within XEngine.
################################################################
################################################################

class CreateXEngineShopifyWebhooks < XEngine::Core::Database::Migration

  # RPECK 23/04/2026 - Dynamically set resource for table naming logic
  set_resource :shopify, :webhook

  def up 
    create_table table_name, **table_options do |t|

			t.belongs_to  :shop, 	foreign_key: { type: :uuid, to_table: shop_table, on_delete: :cascade }, null: false, index: true

      # Shopify Specifics
      t.string :shopify_id, index: true 
      t.string :topic, null: false, index: true
      
      # State
      t.boolean :enabled, default: true, null: false

      t.timestamps

      # Multi-column index for uniqueness and scoped lookups
      t.index [:shop_id, :topic], unique: true, name: "idx_shopify_webhooks_on_shop_and_topic"
    end
  end

  private

  ## RPECK 02/05/2026 - Get the name of the "shop" table
  def shop_table
    XEngine::Core::Model.table_name_for(:shopify, :shop)
  end
  
end
# :startdoc: