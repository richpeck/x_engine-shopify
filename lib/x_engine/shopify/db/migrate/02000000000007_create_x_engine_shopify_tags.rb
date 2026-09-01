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

# frozen_string_literal: true

# = Shopify Tag Database Provisioner
#
# Generates the foundational tracking schema required to store, manage, and index
# reusable classification tags isolated to individual merchant storefront profiles (+XEngine::Shopify::Tag+).
#
# == Schema Layout Matrix
# [id]          System-managed unique primary key handling distributed lookups safely using a native +UUID+ format.
# [shop_id]     The reference link mapping the owner store model. Enforces multi-tenant data isolation.
# [handle]      Unique string slug used for safe platform lookups or administrative routing.
# [title]       The presentation text value representing the tag identity token (e.g., <tt>"Summer-Collection"</tt>).
# [created_at]  Standard ActiveRecord timestamp.
# [updated_at]  Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyTags < XEngine::Core::Database::Migration

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

  # Resolves the database target table directly from the Tag model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::Tag.table_name
  end

  # Resolves the fully namespaced physical table string value for the parent +Shop+ resource.
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

end