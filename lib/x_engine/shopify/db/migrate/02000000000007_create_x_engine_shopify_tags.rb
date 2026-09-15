# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  ________  ___  ___  ________ _________        _________  ________  ________     
##  |\   __  \|\   __  \|\   __  \|\   ___ \|\  \|\  \|\   ____\\___   ___\     |\___   ___\\   __  \|\   ____\    
##  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \___\|___ \  \_|     \|___ \  \_\ \  \|\  \ \  \___|    
##   \ \   ____\ \   _  _\ \  \\\  \ \  \ \\ \ \  \\\  \ \  \       \ \  \           \ \  \ \ \   __  \ \  \  ___  
##    \ \  \___|\ \  \\  \\ \  \\\  \ \  \_\\ \ \  \\\  \ \  \____   \ \  \           \ \  \ \ \  \ \  \ \  \|\  \ 
##     \ \__\    \ \__\\ _\\ \_______\ \_______\ \_______\ \_______\  \ \__\           \ \__\ \ \__\ \__\ \_______\
##      \|__|     \|__|\|__|\|_______|\|_______|\|_______|\|_______|   \|__|            \|__|  \|__|\|__|\|_______|                             
## --
##  RPECK 11/02/2024 - PRoduct Tag object
##  Acts as join model between Product and Collection
################################################################
################################################################

# frozen_string_literal: true

# = Shopify Tag Database Provisioner
#
# Generates the target schema required to persist unique tag entities (+XEngine::Shopify::Tag+).
#
# == Schema Layout Matrix
# [id]         Bigint primary key allowing Shopify numeric GIDs or generated sequences.
# [shop_id]    Foreign reference binding to the owner shop context.
# [name]       The unique plain string token value representing the tag identity.
# [created_at] Standard ActiveRecord timestamp.
# [updated_at] Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyTags < XEngine::Core::Database::Migration

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

      t.string :name, null: false

      t.timestamps

      # Enforce unique tag names per shop
      t.index [:shop_id, :name], unique: true, name: "idx_xe_shopify_tags_shop_name_unique"
    end
  end

  private

  # Resolves the database target table directly from the Tag model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::Tag.table_name
  end

  # Resolves the physical table string value for the companion Shop resource.
  #
  # @return [String]
  def shop_table
    @shop_table ||= XEngine::Shopify::Shop.table_name
  end

end