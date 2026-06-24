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

# = Shopify Webhook Events Database Provisioner
#
# Generates the high-throughput transactional logging schema required to ingest,
# queue, and process un-manipulated asynchronous JSON payloads received from
# the Shopify API cluster.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:webhook_event+
#
# == Schema Layout Matrix
# [+webhook_subscription_id+] The foreign reference link to the matching subscription rule.
# [+shopify_event_id+]        The structural ID returned inside Shopify's +X-Shopify-Webhook-Id+ header.
# [+shop_domain+]             The domain token extracted from Shopify's +X-Shopify-Shop-Domain+ header.
# [+topic+]                   Local copy of the event topic token for fast, decoupled query execution.
# [+payload+]                 The complete, raw +jsonb+ data structure received from the ingress gateway.
# [+processing_status+]       The execution lifecycle state of the event (Default: <tt>"pending"</tt>).
# [+processing_error+]        Text area capturing system stack traces or execution failure exceptions.
#
# == Index Profiles
# * A unique index profile is assigned to <tt>:shopify_event_id</tt> to guarantee idempotent ingestion.
# * A compound indexing layout is mapped to <tt>[:shop_domain, :topic]</tt> to fuel instant multi-tenant administration queries.
#
class CreateXEngineShopifyWebhookEvents < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :webhook_event

  # Executes schema generation transformations on the target database engine layer.
  #
  # === Returns
  # * +void+
  #
  def up
    create_table table_name, **table_options do |t|

      # Establish explicit internal relation binding to the subscription rule
      t.belongs_to :webhook_subscription,
                   type: :uuid,
                   foreign_key: { to_table: subscription_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Ingress Ingestion Telemetry
      t.string :shopify_event_id, null: false
      t.string :shop_domain,      null: false
      t.string :topic,            null: false
      
      # Data Block & Execution Logging
      t.json   :payload,           default: {}, null: false
      t.string :processing_status, default: "pending", null: false, index: true
      t.text   :processing_error

      t.timestamps

      # Guarantee safe structural ingestion barriers via deterministic indexing profiles
      t.index :shopify_event_id, unique: true, name: "idx_shopify_webhook_events_on_event_id"
      t.index [:shop_domain, :topic], name: "idx_shopify_webhook_events_on_shop_and_topic"
    end
  end

  private

  # Resolves the fully namespaced physical table string value for the parent +WebhookSubscription+ resource.
  #
  # === Returns
  # * +String+:: The exact calculated table string target (e.g., +"xe_shopify_webhook_subscriptions"+).
  #
  def subscription_table
    XEngine::Core::Model.table_name_for(:shopify, :webhook_subscription)
  end

end
# :startdoc: