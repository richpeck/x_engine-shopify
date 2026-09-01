# :stopdoc:
################################################################
################################################################
##  ________  ________  ___       ___       _______   ________ _________  ___  ________  ________      
## |\   ____\|\   __  \|\  \     |\  \     |\  ___ \ |\   ____\\___   ___\\  \|\   __  \|\   ___  \    
## \ \  \___|\ \  \|\  \ \  \    \ \  \    \ \   __/|\ \  \___\|___ \  \_\ \  \ \  \|\  \ \  \\ \  \   
##  \ \  \    \ \  \\\  \ \  \    \ \  \    \ \  \_|/_\ \  \       \ \  \ \ \  \ \  \\\  \ \  \\ \  \  
##   \ \  \____\ \  \\\  \ \  \____\ \  \____\ \  \_|\ \ \  \____   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ 
##    \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\  \ \__\ \ \__\ \_______\ \__\\ \__\
##     \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|   \|__|  \|__|\|_______|\|__| \|__|       
##                                                                                                      
## --
## RPECK 18/01/2024 - Collections datatable
## Re-architected mapping suite handling fully hydrated Shopify Collection payloads.
## --
## Ref: https://shopify.dev/docs/api/admin-graphql/2026-04/objects/Collection
################################################################
################################################################

# frozen_string_literal: true

# = Shopify Collection Database Provisioner
#
# Generates the multi-tenant tracking schema required to store, manage, and query
# automated or manual product collections synchronized from the Shopify Admin API layer (+XEngine::Shopify::Collection+).
#
# == Schema Layout Matrix
# [shop_id]        The reference link matching the owner store model.
# [shopify_id]     The raw platform identifier returned from the Shopify GraphQL API.
# [title]          The presentation title name text string for the resource.
# [handle]         Unique string slug used for URL building and SEO routing lookups.
# [body_html]      The raw description rich-text content payload string container.
# [sort_order]     The default collection layout arrangement token string (e.g., <tt>"alpha-asc"</tt>).
# [products_count] Cached calculation counter tracking total assigned child products.
# [published_at]   Timestamp marker tracking exactly when the collection was exposed to sales channels.
# [image_id]       Numeric Shopify GID pointing directly to the collection's primary decorative asset.
# [created_at]     Standard ActiveRecord timestamp.
# [updated_at]     Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyCollections < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|
      
      t.belongs_to :shop, type: :uuid, foreign_key: { to_table: shop_table, on_delete: :cascade }, null: false, index: true

      # Core Text & Descriptive Attributes
      t.string  :title, null: false
      t.string  :handle, null: false
      t.text    :body_html
      t.string  :sort_order

      # Aggregations & Counters
      t.integer :products_count, default: 0, null: false
      
      # Unconstrained bigint column to handle streaming GraphQL bulk payloads where
      # Collection records land before their corresponding ProductMedia lines are parsed.
      t.bigint   :image_id, null: true, index: true

      t.timestamps 

      # Added to give us the ability to scope uniqueness safely around collection routing parameters per-tenant
      t.index [:shop_id, :handle], unique: true, name: "idx_xe_shopify_collections_shop_handle"

    end
  end

  private

  # Resolves the database target table directly from the Collection model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::Collection.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

  # Resolves the fully namespaced physical table string value for the +ProductMedia+ resource.
  # @return [String]
  def media_table
    @media_table ||= XEngine::Shopify::ProductMedia.table_name
  end
  
end