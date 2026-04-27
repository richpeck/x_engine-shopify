# :stopdoc:
################################################################
################################################################
##   ________  ___  ___  ________  ________  ________      
##  |\   ____\|\  \|\  \|\   __  \|\   __  \|\   ____\     
##  \ \  \___|\ \  \\\  \ \  \|\  \ \  \|\  \ \  \___|_    
##   \ \_____  \ \   __  \ \  \\\  \ \   ____\ \_____  \   
##    \|____|\  \ \  \ \  \ \  \\\  \ \  \___|\|____|\  \  
##      ____\_\  \ \__\ \__\ \_______\ \__\     ____\_\  \ 
##     |\_________\|__|\|__|\|_______|\|__|    |\_________\
##     \|_________|                            \|_________|         
##  --
##  RPECK 23/04/2026 - Shopify Shops Migration
##  Defines the schema for Shopify stores within XEngine.
################################################################
################################################################

class CreateXEngineShopifyShops < ActiveRecord::Migration[8.0]

  def table_name
    XEngine::Shopify::Shop.table_name.to_sym
  end

  def up 
    create_table table_name, if_not_exists: true do |t|
      t.string    :api_version
      t.string    :name
      t.string    :myshopify_domain, index: { unique: true, name: 'unique_myshopify_domain' }
      t.string    :email, null: false
      t.string    :url, null: false
      t.string    :currency_code, default: 'USD'

      # Billing Details
      t.string    :billing_address, null: true
      t.string    :billing_city,    null: true
      t.string    :billing_company, null: true
      t.string    :billing_country, null: true
      t.string    :billing_zip,     null: true
      t.string    :billing_phone,   null: true

      # Extras
      t.references  :credential, null: true
      t.jsonb       :meta, default: {}, null: false

      t.timestamps 
    end
  end

  def down 
    drop_table table_name if table_exists?(table_name)
  end
end
# :startdoc: