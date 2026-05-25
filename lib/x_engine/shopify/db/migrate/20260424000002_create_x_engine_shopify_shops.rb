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

# = Shopify Shops Database Provisioner
#
# Generates the multi-tenant tracking schema required to anchor individual
# Shopify merchant environments within the platform core. This profile retains
# core operational metadata, contextual billing geometries, and security linkages.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:shop+
#
# == Schema Layout Matrix
# [api_version]       The standard targeted lock-step Shopify API version string (e.g., <tt>"2026-04"</tt>).
# [name]              The friendly visual display moniker assigned to the store by the merchant.
# [myshopify_domain]  The permanent immutable canonical look-up domain (e.g., <tt>"example.myshopify.com"</tt>).
# [email]             The primary system communication address tracking store alerts.
# [url]               The active external custom storefront web layout address.
# [currency_code]     The standard ISO 4217 three-letter banking token (Default: <tt>"USD"</tt>).
#
# === Billing Elements
# [billing_address]   The street-level location details handling financial transactions.
# [billing_city]      The target municipal zone tracking tax or billing processing.
# [billing_company]   The legal corporate entity profile registered by the vendor client.
# [billing_country]   The country code mapping destination boundaries.
# [billing_zip]       The postal code footprint associated with the merchant card on file.
# [billing_phone]     The absolute dial string routing to corporate headquarters.
#
# === Security & OAuth Elements
# [access_token]      The encrypted offline permanent Admin API token used for node connection routines.
#
# === Core Extensions
# [credential_id]     Foreign key reference pointing to platform app credential tables containing keys and secrets.
# [meta]              A schema-less JSON block handling open context parameters or flags.
#
# == Index Profiles
# * A strict unique database-level constraint is placed across +:myshopify_domain+ to block duplicate tenant collisions.
class CreateXEngineShopifyShops < XEngine::Core::Database::Migration

  # RPECK 23/04/2026 - Dynamically set resource for table naming logic
  set_resource :shopify, :shop

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up 
    create_table table_name, **table_options do |t|
      t.string    :api_version, null: false, default: "2026-04"
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

      # Security & Session Storage
      t.string    :access_token, null: false

      # Extras & Polymorphic/App Linkages
      # Null: false forces every shop to belong to either the global credential profile row or a customized app row
      t.references  :credential, null: false, foreign_key: true
      t.json        :meta, default: {}, null: false

      t.timestamps 
    end
  end

end
# :startdoc: