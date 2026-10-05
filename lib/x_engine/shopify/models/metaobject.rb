####################################
####################################
##   _____ ______   _______  _________  ________  ________  ________        ___  _______   ________ _________   
##  |\   _ \  _   \|\  ___ \|\___   ___\\   __  \|\   __  \|\   __  \      |\  \|\  ___ \ |\   ____\\___   ___\ 
##  \ \  \\\__\ \  \ \   __/\|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\ /_     \ \  \ \   __/|\ \  \___\|___ \  \_| 
##   \ \  \\|__| \  \ \  \_|/__  \ \  \ \ \   __  \ \  \\\  \ \   __  \  __ \ \  \ \  \_|/_\ \  \       \ \  \  
##    \ \  \    \ \  \ \  \_|\ \  \ \  \ \ \  \ \  \ \  \\\  \ \  \|\  \|\  \\_\  \ \  \_|\ \ \  \____   \ \  \ 
##     \ \__\    \ \__\ \_______\  \ \__\ \ \__\ \__\ \_______\ \_______\ \________\ \_______\ \_______\  \ \__\
##      \|__|     \|__|\|_______|   \|__|  \|__|\|__|\|_______|\|_______|\|________|\|_______|\|_______|   \|__|                                                                                           
##                                                                  
## RPECK 18/01/2024 - Metaobject
## Metafield model used to provide the means to add metafield values to objects
## --
## Ref: https://shopify.dev/docs/api/admin-graphql/latest/objects/metaobject
####################################
####################################

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Metaobject Model
    #
    # Manages custom Shopify Metaobject records attached to a parent shop workspace,
    # containing normalized key-value fields.
    #
    # == Database Attributes
    # * <tt>id</tt> (+:bigint+) - Primary key.
    # * <tt>shop_id</tt> (+:bigint+) - Foreign key matching the parent platform store configuration.
    # * <tt>type</tt> (+:string+) - Metaobject definition type (e.g., "custom.specifications").
    # * <tt>handle</tt> (+:string+) - Unique handle identifier for the metaobject within its type.
    #
    class Metaobject < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Populated via standard sync/import jobs; defines the standard subselection payload graph.
      expose_graphql single: :metaobject, multiple: :metaobjects do
        <<~GRAPHQL
          __typename
          id
          type
          handle
          fields {
            key
            value
            type
          }
        GRAPHQL
      end

      # == Associations
      
      # The platform storefront scope instance running the parent initialization workspace.
      belongs_to :shop, class_name: "XEngine::Shopify::Shop", inverse_of: :metaobjects 

      # The collection of normalized key-value field attributes belonging to this metaobject instance.
      has_many :fields, class_name: "XEngine::Shopify::MetaobjectField", dependent: :destroy

      # Manage any of the fields passed through the model
      accepts_nested_attributes_for :fields, allow_destroy: true

    end
  end
end