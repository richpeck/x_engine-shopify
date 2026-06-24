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

# = Shopify Metafield Database Provisioner
#
# Generates the data storage schema layout for high-volume custom metafields. 
# Implements a light, efficient polymorphic structure linked to the parent shop context.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:metafield+
#
class CreateXEngineShopifyMetafields < XEngine::Core::Database::Migration

  # Enforce structural namespacing parameters for the migration table layout target
  set_resource :shopify, :metafield

  # Executes schema generation transformations on the target database engine layer.
  # @return [void]
  def up
    # Force primary_key: false so we can declare our explicit :id column type manually
    localized_options = table_options.merge(id: false)

    create_table table_name, **localized_options do |t|
      # Primary Key matching Shopify's naked numeric GraphQL GID
      t.bigint :id, null: false, primary_key: true

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

  # Resolves the fully namespaced physical table string value for the primary Shop resource.
  # @return [String]
  def shop_table
    XEngine::Core::Model.table_name_for(:shopify, :shop)
  end

end
# :startdoc: