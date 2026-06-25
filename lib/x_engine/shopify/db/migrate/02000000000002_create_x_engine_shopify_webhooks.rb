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
##  RPECK 23/04/2026 - Shopify Webhook Subscriptions Migration
##  Defines the schema for Shopify stores within XEngine.
################################################################
################################################################

# = Shopify Webhooks Database Provisioner
#
# Generates the multi-tenant tracking schema required to register, monitor, 
# and selectively filter asynchronous event notifications dispatched from 
# the Shopify API cluster.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:webhook_subscription+
#
# == Schema Layout Matrix
# [+shop_id+]            The +uuid+ reference link to the owner store model.
# [+shopify_id+]         The unique identification string returned by Shopify's subscription engine.
# [+topic+]              The event string token identifying the hook context (e.g., <tt>orders/create</tt>).
# [+filter+]             An optional GraphQL-compliant matching string used by Shopify to isolate specific payloads.
# [+fields+]             An optional comma-separated string array restricting dimensions of the incoming resource payload data layer.
# [+status+]             The current lifecycle operational state of the endpoint registration (Default: <tt>"disabled"</tt>).
# [+notes+]              Text block for logging application exceptions, failure tracing, or system alert states.
#
# == Index Profiles
# * A composite unique index is assigned across <tt>[:shop_id, :topic]</tt> to prevent duplicate subscription matrices per client tenant.
#
class CreateXEngineShopifyWebhookSubscriptions < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :webhooks

  # Executes schema generation transformations on the target database engine layer.
  #
  # === Returns
  # * +void+
  #
  def up 
    create_table table_name, **table_options do |t|

      # Define the reference column explicitly as a UUID at the macro level
      t.belongs_to :shop, 
                   type: :uuid, 
                   foreign_key: { to_table: shop_table, on_delete: :cascade }, 
                   null: false, 
                   index: true

      # Shopify Specifics
      t.string :shopify_id, index: { unique: true }
      t.string :topic, null: false, index: true
      
      # Payload Optimization & Filtering
      t.string :filter, null: true
      t.string :fields, null: true

      # State & Operational Tracking
      t.string :status, default: "disabled", null: false, index: true
      t.text   :notes

      t.timestamps

      # Multi-column index for uniqueness and scoped lookups
      t.index [:shop_id, :topic], unique: true, name: "idx_shopify_webhooks_on_shop_and_topic"
    end
  end

  private

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  #
  # === Returns
  # * +String+:: The exact calculated table string target (e.g., +"xe_shopify_shops"+).
  #
  def shop_table
    XEngine::Core::Model.table_name_for(:shopify, :shop)
  end
  
end
# :startdoc: