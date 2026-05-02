# :stopdoc:
################################################################
################################################################
##  ________  ___  ___  ___       ___  __            ________  ________  _______   ________  ________  _________  ___  ________  ________          
## |\   __  \|\  \|\  \|\  \     |\  \|\  \         |\   __  \|\   __  \|\  ___ \ |\   __  \|\   __  \|\___   ___\\  \|\   __  \|\   ___  \        
## \ \  \|\ /\ \  \\\  \ \  \    \ \  \/  /|_       \ \  \|\  \ \  \|\  \ \   __/|\ \  \|\  \ \  \|\  \|___ \  \_\ \  \ \  \|\  \ \  \\ \  \       
##  \ \   __  \ \  \\\  \ \  \    \ \   ___  \       \ \  \\\  \ \   ____\ \  \_|/_\ \   _  _\ \   __  \   \ \  \ \ \  \ \  \\\  \ \  \\ \  \      
##   \ \  \|\  \ \  \\\  \ \  \____\ \  \\ \  \       \ \  \\\  \ \  \___|\ \  \_|\ \ \  \\  \\ \  \ \  \   \ \  \ \ \  \ \  \\\  \ \  \\ \  \     
##    \ \_______\ \_______\ \_______\ \__\\ \__\       \ \_______\ \__\    \ \_______\ \__\\ _\\ \__\ \__\   \ \__\ \ \__\ \_______\ \__\\ \__\    
##     \|_______|\|_______|\|_______|\|__| \|__|        \|_______|\|__|     \|_______|\|__|\|__|\|__|\|__|    \|__|  \|__|\|_______|\|__| \|__|   
##  --
##  RPECK 23/04/2026 - Shopify Bulk Operations Migration
##  Defines the schema for Shopify stores within XEngine.
################################################################
################################################################

class CreateXEngineShopifyBulkOperations < XEngine::Core::Database::Migration

  # RPECK 23/04/2026 - Dynamically set resource for table naming logic
  set_resource :shopify, :bulk_operation

  def up 
    create_table table_name, **table_options do |t|

			t.belongs_to  :shop, 	foreign_key: { type: :uuid, to_table: shop_table, on_delete: :cascade }, null: false
			t.string  		:status	            # => integer for enum of the current status of the import (from Shopify's graphQL endpoint)
			t.integer  		:error_code  			  # => integer of the error code raised by the system
			t.bigint   		:file_size				  # => size in bytes of the file
			t.text 	   		:download_url 			# => URL of the file provided by Shopify
			t.integer  		:root_object_count 	# => integer of the number of "root" objects provided by GraphQL
			t.integer  		:object_count 			# => integer of the number of objects provided in the file
			t.text 	   		:query 					    # => query attached to the import
			t.timestamps 
			t.datetime 		:completed_at 			# => datetime of the completed time (provided by Shopify)

			## RPECK 17/12/2024 - Added to give us the ability to scope uniqueness around order name
			t.index [:shop_id, :id], unique: true, name: 'unique_shop_per_id'
    end
  end

  private

  ## RPECK 02/05/2026 - Get the name of the "shop" table
  def shop_table
    XEngine::Core::Model.table_name_for(:shopify, :shop)
  end
  
end
# :startdoc: