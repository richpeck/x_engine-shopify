####################################
####################################
##   _____ ______   _______  _________  ________  ________ ___  _______   ___       ________     
##  |\   _ \  _   \|\  ___ \|\___   ___\\   __  \|\  _____\\  \|\  ___ \ |\  \     |\   ___ \    
##  \ \  \\\__\ \  \ \   __/\|___ \  \_\ \  \|\  \ \  \__/\ \  \ \   __/|\ \  \    \ \  \_|\ \   
##   \ \  \\|__| \  \ \  \_|/__  \ \  \ \ \   __  \ \   __\\ \  \ \  \_|/_\ \  \    \ \  \ \\ \  
##    \ \  \    \ \  \ \  \_|\ \  \ \  \ \ \  \ \  \ \  \_| \ \  \ \  \_|\ \ \  \____\ \  \_\\ \ 
##     \ \__\    \ \__\ \_______\  \ \__\ \ \__\ \__\ \__\   \ \__\ \_______\ \_______\ \_______\
##      \|__|     \|__|\|_______|   \|__|  \|__|\|__|\|__|    \|__|\|_______|\|_______|\|_______|                                                                                             
##                                                                  
##  --
##  RPECK 21/06/2026 - Metafield Migration
##  Provisions the polymorphic tracking architecture for storing Shopify custom attributes.
################################################################
################################################################

# frozen_string_literal: true

# = Shopify Metafield Database Provisioner
#
# Generates the data storage schema layout for high-volume custom metafields. 
# Implements a light, efficient polymorphic structure linked to the parent shop context (+XEngine::Shopify::Metafield+).
#
# == Schema Layout Matrix
# [id]              Primary Key matching Shopify's naked numeric GraphQL GID.
# [shop_id]         The foreign reference link to the owner shop profile.
# [objectable_type] Polymorphic type string for the owner record.
# [objectable_id]   Polymorphic identifier for the owner record.
# [namespace]       Structural namespace grouping key for the metafield.
# [key]             Unique key identifier for the metafield within its namespace.
# [value]           Serialized or raw string value of the metafield.
# [created_at]      Standard ActiveRecord timestamp.
# [updated_at]      Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyMetafields < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|

      # Parent Store Association Scope Boundary
      t.belongs_to :shop, 
                   type: :uuid, 
                   foreign_key: { to_table: shop_table, on_delete: :cascade }, 
                   null: false

      # Polymorphic Owner References (Handles Products / ProductVariants via bigint IDs)
      t.string :objectable_type, null: false
      t.bigint :objectable_id,   null: false

      # Structural Metadata Keyspace
      t.string :namespace, null: false
      t.string :key,       null: false
      t.text   :value,     null: false

      t.timestamps

      # Indexes for Polymorphic Queries and Rapid Scans
      t.index [:objectable_type, :objectable_id], 
              name: "idx_xe_shopify_metafields_poly"

      # Structural Uniqueness Constraints to prevent synchronization duplicate collisions
      t.index [:objectable_type, :objectable_id, :namespace, :key], 
              unique: true, 
              name: "idx_xe_shopify_metafields_uniq_key"
    end
  end

  private

  # Resolves the database target table directly from the Metafield model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::Metafield.table_name
  end

  # Resolves the fully namespaced physical table string value for the primary Shop resource.
  #
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

end