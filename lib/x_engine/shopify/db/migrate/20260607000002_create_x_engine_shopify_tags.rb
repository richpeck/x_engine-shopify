# :stopdoc:
################################################################
################################################################
##  _________  ________  ________                               
## |\___   ___\\   __  \|\   ____\                              
## \|___ \  \_\ \  \|\  \ \  \___|                              
##      \ \  \ \ \   __  \ \  \  ___                            
##       \ \  \ \ \  \ \  \ \  \|\  \                           
##        \ \__\ \ \__\ \__\ \_______\                          
##         \|__|  \|__|\|__|\|_______|                          
##                                                              
## --
## RPECK 17/01/2024 - Tags Datatable
## Defines the shop-scoped multi-tenant schema for storing tags within XEngine.
################################################################
################################################################

# = Shopify Tag Database Provisioner
#
# Generates the foundational tracking schema required to store, manage, and index
# reusable classification tags isolated to individual merchant storefront profiles.
#
# == Database Resource Configuration
# * *Namespace:* +:shopify+
# * *Resource:* +:tag+
#
# == Schema Layout Matrix
# [id]          System-managed unique primary key handling distributed lookups safely using a native +UUID+ format.
# [shop_id]     The reference link mapping the owner store model. Enforces multi-tenant data isolation.
# [handle]      Unique string slug used for safe platform lookups or administrative routing.
# [title]       The presentation text value representing the tag identity token (e.g., <tt>"Summer-Collection"</tt>).
#
# == Architectural Guardrails
# * *Multi-Tenant Uniqueness:* Scopes the unique constraint to the <tt>shop_id</tt> layer, allowing duplicate 
#   tag names across different merchant platforms while preventing duplication within the same store footprint.
class CreateXEngineShopifyTags < XEngine::Core::Database::Migration

  # Trigger dynamic routing mapping variables for engine table namespaces.
  set_resource :shopify, :tag

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    create_table table_name, **table_options do |t|

      t.belongs_to :shop, type: :uuid, foreign_key: { to_table: shop_table, on_delete: :cascade }, null: false, index: true
      t.string     :handle
      t.string     :title, null: false

      t.timestamps

      # Maintain store-scoped distinct validation on the tag label strings
      t.index [:shop_id, :title], unique: true, name: "idx_xe_shopify_tags_unique_per_shop"

    end
  end

  private

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  # @return [String]
  def shop_table
    XEngine::Core::Model.table_name_for(:shopify, :shop)
  end

end
# :startdoc: