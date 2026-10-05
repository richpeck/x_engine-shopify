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

module XEngine
  module Shopify
    # = Shopify Metaobject Field Model
    #
    # Manages individual key-value attributes belonging to a parent Shopify Metaobject record,
    # mapping scalar values and field definition types.
    #
    # == Database Attributes
    # * <tt>id</tt> (+:bigint+) - Primary key.
    # * <tt>metaobject_id</tt> (+:bigint+) - Foreign key matching the parent metaobject model.
    # * <tt>key</tt> (+:string+) - Field key name identifier.
    # * <tt>value</tt> (+:text+) - Raw string or serialized value payload.
    # * <tt>field_type</tt> (+:string+) - Shopify field definition type (e.g., "single_line_text_field").
    #
    class MetaobjectField < XEngine::Core::Model

      # == Associations

      # The parent metaobject record owning this field attribute.
      belongs_to :metaobject, class_name: "XEngine::Shopify::Metaobject", inverse_of: :fields

      # Ensure the "key" is present in the field, otherwise not work storing
      validates :key, presence: true

    end
  end
end