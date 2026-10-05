# :stopdoc:
################################################################
################################################################
##   _____ ______   _______  _________  ________  ________  ________        ___  _______   ________ _________        ________ ___  _______   ___       ________     
##  |\   _ \  _   \|\  ___ \|\___   ___\\   __  \|\   __  \|\   __  \      |\  \|\  ___ \ |\   ____\\___   ___\     |\  _____\\  \|\  ___ \ |\  \     |\   ___ \    
##  \ \  \\\__\ \  \ \   __/\|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\ /_     \ \  \ \   __/|\ \  \___\|___ \  \_|     \ \  \__/\ \  \ \   __/|\ \  \    \ \  \_|\ \   
##   \ \  \\|__| \  \ \  \_|/__  \ \  \ \ \   __  \ \  \\\  \ \   __  \  __ \ \  \ \  \_|/_\ \  \       \ \  \       \ \   __\\ \  \ \  \_|/_\ \  \    \ \  \ \\ \  
##    \ \  \    \ \  \ \  \_|\ \  \ \  \ \ \  \ \  \ \  \\\  \ \  \|\  \|\  \\_\  \ \  \_|\ \ \  \____   \ \  \       \ \  \_| \ \  \ \  \_|\ \ \  \____\ \  \_\\ \ 
##     \ \__\    \ \__\ \_______\  \ \__\ \ \__\ \__\ \_______\ \_______\ \________\ \_______\ \_______\  \ \__\       \ \__\   \ \__\ \_______\ \_______\ \_______\
##      \|__|     \|__|\|_______|   \|__|  \|__|\|__|\|_______|\|_______|\|________|\|_______|\|_______|   \|__|        \|__|    \|__|\|_______|\|_______|\|_______|                                                                                      
##                                                                                                                                 
## --
## RPECK 18/01/2024 - Metaobject Field
## Metaobject Fields used to provide the means to populate a metaobject using key/value pairs
## --
## Ref: https://shopify.dev/docs/api/admin-graphql/latest/objects/MetaobjectField
####################################
####################################

# frozen_string_literal: true

# = Shopify Metaobject Field Database Provisioner
#
# Generates the target schema for persisting normalized individual field attributes
# belonging to a Shopify Metaobject (+XEngine::Shopify::MetaobjectField+).
#
# == Schema Layout Matrix
# [id]            Bigint primary key.
# [metaobject_id] Foreign reference binding to the parent metaobject model. Enforces cascading delete.
# [key]           Field key name (e.g., "title", "color", "rating").
# [value]         Raw or scalar text value representation.
# [field_type]    Shopify definition type for the field (e.g., "single_line_text_field", "number_integer").
# [created_at]    Standard ActiveRecord timestamp.
# [updated_at]    Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyMetaobjectFields < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|
      t.belongs_to :metaobject,
                   type: :bigint,
                   foreign_key: { to_table: metaobject_table, on_delete: :cascade },
                   null: false,
                   index: true

      t.string :key, null: false
      t.text :value
      t.string :field_type

      t.timestamps

      # Compound index ensuring a single unique key entry per metaobject instance
      t.index [:metaobject_id, :key], unique: true, name: "idx_xe_shopify_metaobject_fields_unique"
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
    @table_name ||= XEngine::Shopify::MetaobjectField.table_name
  end

  def metaobject_table
    @metaobject_table ||= XEngine::Shopify::Metaobject.table_name
  end
end