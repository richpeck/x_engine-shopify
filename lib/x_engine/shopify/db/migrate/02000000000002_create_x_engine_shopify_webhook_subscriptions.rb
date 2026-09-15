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

# frozen_string_literal: true

# = Shopify Webhooks Database Provisioner
#
# Generates the multi-tenant tracking schema required to register, monitor, 
# and selectively filter asynchronous event notifications dispatched from 
# the Shopify API cluster (+XEngine::Shopify::WebhookSubscription+).
#
# == Schema Layout Matrix
# [id]         Canonical string primary key storing the extracted Shopify ID or GID string.
# [shop_id]    The +uuid+ reference link to the owner store model.
# [name]       A human-readable label identifying the registration context.
# [topic]      The event string token identifying the hook context (e.g., <tt>orders/create</tt>).
# [uri]        The target callback endpoint URI or URL destination registered with Shopify.
# [api_version] The Shopify API version string associated with the subscription payload.
# [filter]     An optional GraphQL-compliant matching string used by Shopify to isolate specific payloads.
# [fields]     An optional comma-separated string array restricting dimensions of the incoming resource payload data layer.
# [notes]      Text block for logging application exceptions, failure tracing, or system alert states.
# [created_at] Standard ActiveRecord timestamp.
# [updated_at] Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyWebhookSubscriptions < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # === Returns
  # * +void+
  #
  def up 
    # Allocate :string to id column to allow storing raw string GIDs or numeric IDs directly.
    localized_options = table_options.merge(id: :string, default: nil)

    create_table table_name, **localized_options do |t|

      # Belonging Shop (UUID Scope)
      t.belongs_to :shop, 
                   type: :uuid, 
                   foreign_key: { to_table: shop_table, on_delete: :cascade }, 
                   null: false, 
                   index: true

      # Metadata & Human Interface
      t.string :name, null: true

      # Shopify Remote Identity & Settings
      t.string :topic, null: false, index: true
      t.text   :uri, null: true
      t.string :api_version, null: true
      
      # Payload Filtering & Query Optimizations
      t.text   :filter, null: true
      t.text   :fields, null: true

      # State & Operational Tracking
      t.text   :notes

      t.timestamps

      # Primary conflict target for bulk upserts across tenant shops
      t.index [:shop_id, :id], unique: true, name: "idx_shopify_webhooks_shop_id"

      # Compound index supporting multi-endpoint configurations per topic
      t.index [:shop_id, :topic, :uri], unique: true, name: "idx_shopify_webhooks_shop_topic_uri"
    end
  end

  private

  # Resolves the database target table directly from the Webhook model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::WebhookSubscription.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  #
  # === Returns
  # * +String+:: The exact calculated table string target (e.g., +"xe_shopify_shops"+).
  #
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end
end