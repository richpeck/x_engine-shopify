# :stopdoc:
################################################################
################################################################
##   _____ ______   _______   ________  ___  ________     
##  |\   _ \  _   \|\  ___ \ |\   ___ \|\  \|\   __  \    
##  \ \  \\\__\ \  \ \   __/|\ \  \_|\ \ \  \ \  \|\  \   
##   \ \  \\|__| \  \ \  \_|/_\ \  \ \\ \ \  \ \   __  \  
##    \ \  \    \ \  \ \  \_|\ \ \  \_\\ \ \  \ \  \ \  \ 
##     \ \__\    \ \__\ \_______\ \_______\ \__\ \__\ \__\
##      \|__|     \|__|\|_______|\|_______|\|__|\|__|\|__|     
##  --
##  RPECK 06/06/2026 - Shopify Product Media Migration
##  Defines the schema for product media assets within XEngine.
################################################################
################################################################

# frozen_string_literal: true

# = Shopify Product Media Database Provisioner
#
# Generates the multi-tenant tracking schema required to store and manage 
# rich media resources synchronized from the Shopify API cluster (+XEngine::Shopify::ProductMedia+).
#
# == Schema Layout Matrix
# [id]         System-managed unique primary key handling distributed lookups safely using a native +UUID+ format.
# [shop_id]    The reference link matching the owner store model.
# [shopify_id] The unique identifier string passed directly from the Shopify Admin API.
# [url]        The static CDN location string for the asset payload.
# [height]     The pixel elevation footprint of the media asset.
# [width]      The pixel dimensional spread of the media asset.
# [alt]        The text accessibility fallback string for SEO or display rendering.
# [media_type] The explicit asset token identifying content rules (e.g., <tt>"image"</tt>, <tt>"video"</tt>).
# [meta]       A schema-less JSON block handling customizable platform metadata parameters or overrides.
# [created_at] Standard ActiveRecord timestamp.
# [updated_at] Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyProductMedia < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up 
    create_table table_name, **table_options do |t|

      t.belongs_to :shop, type: :uuid, foreign_key: { to_table: shop_table, on_delete: :cascade }, null: false, index: true

      # Shopify Specifics
      t.string :shopify_id, index: { unique: true }
      
      # Core Media Attributes
      t.string  :url, null: false
      t.integer :height
      t.integer :width
      t.string  :alt
      t.string  :media_type, default: "image", null: false, index: true

      # Open tracking config block consistent with engine schemas
      t.json    :meta, default: {}, null: false

      t.timestamps 
    end
  end

  private

  # Resolves the database target table directly from the ProductMedia model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::ProductMedia.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  #
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

end