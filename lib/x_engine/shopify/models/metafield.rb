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
## RPECK 18/01/2024 - Metafield
## Metafield model used to provide the means to add metafield values to objects
## --
## Ref: https://shopify.dev/docs/api/admin-graphql/latest/objects/metafield
####################################
####################################

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Metafield Model
    #
    # Manages contextual key-value metadata attributes attached polymorphically to core 
    # Shopify resources like Products or ProductVariants, restricted within a parent shop workspace.
    #
    # == Database Attributes
    # * <tt>id</tt> (+:bigint+) - The naked numeric Shopify GID value serving as the primary key.
    # * <tt>shop_id</tt> (+:bigint+) - Foreign key matching the parent platform store configuration.
    # * <tt>objectable_type</tt> (+:string+) - Polymorphic class discriminator type of the target owner record.
    # * <tt>objectable_id</tt> (+:bigint+) - Polymorphic foreign key value referencing the target owner record.
    # * <tt>namespace</tt> (+:string+) - Structural container grouping key mappings (e.g., "custom").
    # * <tt>key</tt> (+:string+) - Explicit identification token mapped inside the target namespace.
    # * <tt>value</tt> (+:text+) - Long-form string or serialized JSON object payload payload data.
    #
    class Metafield < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Populated via standard sync/import jobs; defines the standard subselection payload graph.
      expose_graphql do
        <<~GRAPHQL
          __typename
          id
          shopify_id: id
          namespace
          key
          value
          type
        GRAPHQL
      end

      # == Associations
      
      # The platform storefront scope instance running the parent initialization workspace.
      belongs_to :shop, class_name: "XEngine::Shopify::Shop", inverse_of: :metafields
      
      # The abstract polymorphic target record containing this metadata payload allocation.
      belongs_to :objectable, polymorphic: true

      # == Validations
      validates :namespace, presence: true
      validates :key, presence: true, uniqueness: { scope: [:objectable_type, :objectable_id, :namespace] }
      validates :value, presence: true
    end
  end
end