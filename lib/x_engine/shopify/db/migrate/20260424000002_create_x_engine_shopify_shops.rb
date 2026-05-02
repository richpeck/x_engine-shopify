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

class CreateXEngineShopifyShops < XEngine::Core::Database::Migration

  # RPECK 23/04/2026 - Dynamically set resource for table naming logic
  set_resource :shopify, :shop

  def up 
    create_table table_name, **table_options do |t|
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
      t.json        :meta, default: {}, null: false

      t.timestamps 
    end
  end

end
# :startdoc: