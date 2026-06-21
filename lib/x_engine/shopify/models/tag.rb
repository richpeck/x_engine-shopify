# :stopdoc:
################################################################
################################################################
##   _________  ________  ________     
##  |\___   ___\\   __  \|\   ____\    
##  \|___ \  \_\ \  \|\  \ \  \___|    
##       \ \  \ \ \   __  \ \  \  ___  
##        \ \  \ \ \  \ \  \ \  \|\  \ 
##         \ \__\ \ \__\ \__\ \_______\
##          \|__|  \|__|\|__|\|_______|                                                      
##  --
## RPECK 17/01/2024 - Tag object
## Pulls in tag data, which can then be used to populate product tags
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Product Tag Model
    #
    # Manages synchronization layers, taxonomy classifications, and structural handles
    # mapping products to shared categorization boundaries throughout the workspace ecosystem.
    #
    # == Lifecycle Integration
    # This resource automatically includes the {XEngine::Shopify::HasHandle} concern
    # to guarantee consistent string normalization for SEO-friendly routing handles.
    # It leverages {XEngine::Shopify::HasGraphQLRepresentation} strictly to state its 
    # field footprint string definitions when embedded inside upstream parent queries.
    #
    class Tag < XEngine::Core::Model
      include XEngine::Shopify::HasHandle
      include XEngine::Shopify::HasGraphQLRepresentation

      # Registers the class context as an active shopify resource entity layer
      expose_as :shopify, :product_tag

      # Automatically normalize the title attribute into the handle column before execution
      has_handle :title

      # == GraphQL Layout Declarations
      # Exposed strictly as a scalar string list representation component.
      # Shopify returns tags directly on the product node as an array of strings.
      expose_graphql do
        <<~GRAPHQL
          tags
        GRAPHQL
      end

      # == Associations
      has_and_belongs_to_many :products, -> { distinct }, class_name: "XEngine::Shopify::Product"

      # == Validations
      validates :title, presence: true
    end
  end
end