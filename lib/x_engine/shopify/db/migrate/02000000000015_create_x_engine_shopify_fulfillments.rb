# :stopdoc:
################################################################
################################################################
##   ________ ___  ___  ___       ________ ___  ___       ___       _____ ______   _______   ________   _________  ________      
##  |\  _____\\  \|\  \|\  \     |\  _____\\  \|\  \     |\  \     |\   _ \  _   \|\  ___ \ |\   ___  \|\___   ___\\   ____\     
##  \ \  \__/\ \  \\\  \ \  \    \ \  \__/\ \  \ \  \    \ \  \    \ \  \\\__\ \  \ \   __/|\ \  \\ \  \|___ \  \_\ \  \___|_    
##   \ \   __\\ \  \\\  \ \  \    \ \   __\\ \  \ \  \    \ \  \    \ \  \\|__| \  \ \  \_|/_\ \  \\ \  \   \ \  \ \ \_____  \   
##    \ \  \_| \ \  \\\  \ \  \____\ \  \_| \ \  \ \  \____\ \  \____\ \  \    \ \  \ \  \_|\ \ \  \\ \  \   \ \  \ \|____|\  \  
##     \ \__\   \ \_______\ \_______\ \__\   \ \__\ \_______\ \_______\ \__\    \ \__\ \_______\ \__\\ \__\   \ \__\  ____\_\  \ 
##      \|__|    \|_______|\|_______|\|__|    \|__|\|_______|\|_______|\|__|     \|__|\|_______|\|__| \|__|    \|__| |\_________\
##                                                                                                                    \|_________|                                                                                                                                      
##  --
##  RPECK 24/06/2026 - Create Shopify Refund Line Items Migration
##  Defines the schema for linking refunded products back to transaction rollbacks within XEngine.
################################################################
################################################################

# frozen_string_literal: true

# = Create Shopify Fulfillments Database Provisioner
#
# Generates the physical relation map table used to inventory tracking milestones,
# fulfillment state flags, and delivery courier references (+XEngine::Shopify::Fulfillment+).
#
# == Schema Layout Matrix
# [order_id]         The foreign reference link to the specific parent order record.
# [name]             The human-readable name or identifier of the fulfillment.
# [status]           The processing or delivery status of the fulfillment.
# [tracking_company] The name of the shipping carrier or courier company.
# [tracking_numbers] Serialized or split delivery tracking numbers.
# [tracking_urls]    Serialized or split delivery tracking URLs.
# [created_at]       Standard ActiveRecord timestamp.
# [updated_at]       Standard ActiveRecord timestamp.
#
class CreateXEngineShopifyFulfillments < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Allocate bigint to id column to override the global UUID default strategy.
    # Ensures we are able to use the numeric GID from Shopify as the naked table primary key identifier.
    localized_options = table_options.merge(id: :bigint, default: nil)

    create_table table_name, **localized_options do |t|

      # Strict relationship binding to the parent order record
      t.belongs_to :order,
                   type: :bigint,
                   foreign_key: { to_table: order_table, on_delete: :cascade },
                   null: false,
                   index: true

      # Operational and Tracking Metrics
      t.string :name
      t.string :status
      t.string :tracking_company
      
      # Text blocks to cleanly handle split or serialized delivery tracking pointers
      t.text :tracking_numbers
      t.text :tracking_urls

      t.timestamps
    end
  end

  private

  # Resolves the database target table directly from the Fulfillment model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Shopify::Fulfillment.table_name
  end

  # Resolves the fully namespaced physical table string value for the companion Order resource.
  #
  # @return [String]
  def order_table
    @order_table ||= XEngine::Shopify::Order.table_name
  end

end