# :stopdoc:
################################################################
################################################################
##   ___       __   _______   ________  ___  ___  ________  ________  ___  __       
##  |\  \     |\  \|\  ___ \ |\   __  \|\  \|\  \|\   __  \|\   __  \|\  \|\  \     
##  \ \  \    \ \  \ \   __/|\ \  \|\ /\ \  \\\  \ \  \|\  \ \  \|\  \ \  \/  /|_   
##   \ \  \  __\ \  \ \  \_|/_\ \   __  \ \   __  \ \  \\\  \ \  \\\  \ \   ___  \  
##    \ \  \|\__\_\  \ \  \_|\ \ \  \|\  \ \  \ \  \ \  \\\  \ \  \\\  \ \  \\ \  \ 
##     \ \____________\ \_______\ \_______\ \__\ \__\ \_______\ \_______\ \__\\ \__\
##      \|____________|\|_______|\|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|
##  --
##  RPECK 22/06/2026 - Shopify Webhook Model Extenstion
##  USed to add the various refine UI column definitions
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "x_engine/shopify/models/webhook_subscription" rescue nil

module XEngine
  module Shopify
    # Reopens {XEngine::Shopify::WebhookSubscription} to declare schema metadata,
    # associations, and global filter rules consumed by the frontend Refine dashboard components (+GenericList+).
    #
    # @see RefineSchema
    class WebhookSubscription < XEngine::Core::Model
      include XInventory::Concerns::ParamsSchema
      include XInventory::Concerns::RefineSchema
      include Concerns::SerializableModel

      # Callbacks
      before_validation :set_default_uri, on: :create

      # Permitted Shopify webhook topic subscriptions
      TOPICS = [
        "bulk_operations/finish",
        "collections/create",
        "collections/delete",
        "collections/update",
        "fulfillments/create",
        "fulfillments/update",
        "orders/create",
        "orders/delete",
        "orders/edited",
        "orders/paid",
        "orders/update",
        "order_transactions/create",
        "products/create",
        "products/delete",
        "products/update",
        "refunds/create"
      ].freeze
      
      # Polymorphic link to associated execution job records
      has_many :job_records, 
               as: :target, 
               class_name: "XEngine::Core::JobRecord", 
               dependent: :destroy

      # =========================================================================
      # :section: Ingress Parameter Validation Schema
      # =========================================================================

      params_schema do
        required(:shop_id).filled(:string)
        required(:topic).filled(:string)
        optional(:uri).maybe(:string)
        optional(:filters).maybe(:string)
        optional(:name).maybe(:string)
      end

      # =========================================================================
      # Refine Dashboard Schema Configuration
      # =========================================================================

      # Explicitly set the API resource key to override the XEngine namespace default
      resource_key "webhooks"

      # Localization key for the Webhook resource
      label_key "resources.webhooks.name"

      # Permitted Refine actions
      actions :index, :show, :create, :delete, :resync

      # Attributes targeted during global fuzzy string searches
      search_by :topic, :shopify_id

      # Attributes permitted for server-side sorting
      sortable_columns :name, :shopify_id, :shop, :topic, :job_records_count, :created_at

      # Default sorting preference when initial view renders
      initial_sort :created_at, :desc

      # Primary attributes displayed in the index table view
      index_columns :shopify_id, :shop, :name, :topic, :uri, :created_at, :updated_at

      # Detailed column definitions including visibility capabilities and localization
      column :shop_id,           label_key: "resources.webhooks.fields.shop",               enabled_on: %i[create], type: :shop_select, required: true, options: -> { XEngine::Shopify::Shop.pluck(:name, :id) }
      column :name,              label_key: "resources.webhooks.fields.name",               enabled_on: %i[index show create], sortable: true
      column :uri,               label_key: "resources.webhooks.fields.url",                enabled_on: %i[index show], sortable: false, required: false, placeholder: "Auto-generated if left blank"
      column :shopify_id,        label_key: "resources.webhooks.fields.shopify_id",        enabled_on: %i[index show edit], sortable: true
      column :topic,             label_key: "resources.webhooks.fields.topic",              enabled_on: %i[index show edit create], required: true, sortable: true, type: :select, options: TOPICS
      column :job_records_count, label_key: "resources.webhooks.fields.job_records_count", enabled_on: %i[index show], sortable: true
      column :filters,           label_key: "resources.webhooks.fields.filters",           enabled_on: %i[create], type: :string, placeholder: "e.g. ['tag:VIP']"
      column :created_at,        label_key: "resources.webhooks.fields.created_at",        enabled_on: %i[index show], sortable: true
      column :updated_at,        label_key: "resources.webhooks.fields.updated_at",        enabled_on: %i[index show], sortable: true

      # Global header filter controls rendered on the index page
      filter_by :shop, type: :select, label: "Shop", options: -> { XEngine::Shopify::Shop.pluck(:name, :id) }

      # ---
      # :section: Serialization Hooks
      # ---

      # Converts the webhook model instance into a JSON-compatible Hash representation.
      default_json_options methods: %i[job_records_count],
                           include: {
                             shop: { only: %i[id name domain myshopify_domain] }
                           }

      private

      # Assigns the canonical endpoint URI using the shop instance method
      def set_default_uri
        return if uri.present?
        return unless shop.present?

        self.uri = shop.webhook_callback_url(topic)
      end
    end
  end
end