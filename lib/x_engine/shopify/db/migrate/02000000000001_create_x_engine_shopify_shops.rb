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
# [id]                System-managed unique primary key handling tenant routing safely using a native +UUID+ format.
# [api_version]       The standard targeted lock-step Shopify API version string (e.g., <tt>"2026-04"</tt>).
# [name]              The friendly visual display moniker assigned to the store by the merchant.
# [myshopify_domain]  The permanent immutable canonical look-up domain (e.g., <tt>"example.myshopify.com"</tt>).
# [email]             The primary system communication address tracking store alerts.
# [url]               The active external custom storefront web layout address.
# [currency_code]     The standard ISO 4217 three-letter banking token (Default: <tt>"USD"</tt>).
# [credential_id]     Foreign key reference pointing to platform app credential tables containing OAuth parameters.
# [meta]              A schema-less JSON block handling open context parameters or flags.
#
# === Billing Elements
# [billing_address]   The street-level location details handling financial transactions.
# [billing_city]      The target municipal zone tracking tax or billing processing.
# [billing_company]   The legal corporate entity profile registered by the vendor client.
# [billing_country]   The country code mapping destination boundaries.
# [billing_zip]       The postal code footprint associated with the merchant card on file.
# [billing_phone]     The absolute dial string routing to corporate headquarters.
#
# == Architectural Guardrails
# * *Strict Domain Segregation:* Enforces a database-level distinct unique token index check on the <tt>myshopify_domain</tt> value row to guarantee secure workspace separation.
# * *Aligned BigInt Mappings:* Overrides reference typing on the <tt>credential_id</tt> block to bind correctly with structural core authorization math indexes.
class CreateXEngineShopifyShops < XEngine::Core::Database::Migration

  # Dynamically set resource for table naming logic
  set_resource :shopify, :shop

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up 
    create_table table_name, **table_options do |t|
      t.string    :name
      t.string    :myshopify_domain, null: false
      t.string    :email
      t.string    :url
      t.string    :currency_code, default: "USD"
      t.datetime  :api_expires

      # Extras & Structural Mappings
      # UPGRADE: Force type: :uuid to prevent data constraint mismatch errors when referencing core credentials
      t.references :credential, 
                   type: :uuid, 
                   null: false, 
                   foreign_key: { to_table: credential_table, on_delete: :restrict }, 
                   index: true
                   
      t.json      :meta, default: {}, null: false

      t.timestamps 

      # Enforce explicit system index parameters tracking primary domain routing keys
      t.index :myshopify_domain, unique: true, name: "idx_xe_shopify_shops_unique_domain"
    end
  end

  private

  # Resolves the fully namespaced physical table string value for the Core Credential engine target.
  # @return [String]
  def credential_table
    XEngine::Core::Model.table_name_for(:core, :credential)
  end

end
# :startdoc: