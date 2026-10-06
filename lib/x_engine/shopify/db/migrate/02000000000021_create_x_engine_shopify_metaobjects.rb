# :stopdoc:
################################################################
################################################################
##   _____ ______   _______  _________  ________  ________  ________        ___  _______   ________ _________   
##  |\   _ \  _   \|\  ___ \|\___   ___\\   __  \|\   __  \|\   __  \      |\  \|\  ___ \ |\   ____\\___   ___\ 
##  \ \  \\\__\ \  \ \   __/\|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\ /_     \ \  \ \   __/|\ \  \___\|___ \  \_| 
##   \ \  \\|__| \  \ \  \_|/__  \ \  \ \ \   __  \ \  \\\  \ \   __  \  __ \ \  \ \  \_|/_\ \  \       \ \  \  
##    \ \  \    \ \  \ \  \_|\ \  \ \  \ \ \  \ \  \ \  \\\  \ \  \|\  \|\  \\_\  \ \  \_|\ \ \  \____   \ \  \ 
##     \ \__\    \ \__\ \_______\  \ \__\ \ \__\ \__\ \_______\ \_______\ \________\ \_______\ \_______\  \ \__\
##      \|__|     \|__|\|_______|   \|__|  \|__|\|__|\|_______|\|_______|\|________|\|_______|\|_______|   \|__|                                                                                           
##                                                                                                                                 
## --
## RPECK 18/01/2024 - Metaobject
## Metafield model used to provide the means to add metafield values to objects
## --
## Ref: https://shopify.dev/docs/api/admin-graphql/latest/objects/metaobject
####################################
####################################

# frozen_string_literal: true

# = Shopify Metaobject Database Provisioner
#
# Generates the target schema for persisting top-level Shopify Metaobject records
# (+XEngine::Shopify::Metaobject+).
#
# == Schema Layout Matrix
# [id]         Bigint primary key.
# [shop_id]    Foreign reference binding to the parent shop model. Enforces cascading delete.
# [type]       Metaobject definition type (e.g. "custom.specifications").
# [handle]     Unique handle identifier for the metaobject within its type namespace.
# [created_at] Standard ActiveRecord timestamp.
# [updated_at] Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyMetaobjects < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|
      t.belongs_to :shop,
                   type: :uuid,
                   foreign_key: { to_table: shop_table, on_delete: :cascade },
                   null: false,
                   index: true

      t.string :type, null: false
      t.string :handle, null: false

      t.timestamps

      # Compound index enforcing unique metaobject handles per shop and type
      t.index [:shop_id, :type, :handle], unique: true, name: "idx_xe_shopify_metaobjects_unique"

      # Index for filtering metaobjects by type across a shop
      t.index [:shop_id, :type], name: "idx_xe_shopify_metaobjects_type_lookup"
    end
  end

  # Reverts schema generation transformations.
  #
  # @return [void]
  def down
    drop_table table_name if table_exists?(table_name)
  end

  private

  def table_name
    @table_name ||= XEngine::Shopify::Metaobject.table_name
  end

  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end
end