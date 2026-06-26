# :stopdoc:
################################################################
################################################################
##  ________  ___  ___  ___       ___  __              ________  ________  _______   ________  ________  _________  ___  ________  ________      
## |\   __  \|\  \|\  \|\  \     |\  \|\  \           |\   __  \|\   __  \|\  ___ \ |\   __  \|\   __  \|\___   ___\\  \|\   __  \|\   ___  \    
## \ \  \|\ /\ \  \\\  \ \  \    \ \  \/  /|_         \ \  \|\  \ \  \|\  \ \  \__ /|\ \  \|\ \ \  \|\  \|___ \  \_\ \  \ \  \|\  \ \  \\ \  \   
##  \ \   __  \ \  \\\  \ \  \    \ \   ___  \         \ \  \\\  \ \   ____\ \  \_|/_\ \  _  __\ \  .__  \   \ \  \ \ \  \ \  \\\  \ \  \\ \  \  
##   \ \  \|\  \ \  \\\  \ \  \____\ \  \\ \  \         \ \  \\\  \ \  \___|\ \  \_|\ \ \  \\  \\ \  \ \  \   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ 
##    \ \_______\ \_______\ \_______\ \__\\ \__\         \ \_______\ \__\    \ \_______\ \__\\ _\\ \__\ \__\   \ \__\ \ \__\ \_______\ \__\\ \__\
##     \|_______|\|_______|\|_______|\|__| \|__|          \|_______|\|__|     \|_______|\|__|\|__|\|__|\|__|    \|__|  \|__|\|_______|\|__| \|__|
##                                                                                                                                            
## --
##  RPECK 24/01/2024 - Shopify Bulk Operation Management
##  Gives us the ability to tie an import to a bulk operation
##  Ref: https://shopify.dev/docs/api/admin-graphql/latest/objects/bulkoperation
################################################################
################################################################
# :stopdoc:

# frozen_string_literal: true

require "open-uri"

module XEngine
  module Shopify
    # = Shopify Bulk Operation Model
    #
    # Tracks asynchronous GraphQL bulk data operations initiated against Shopify's cloud 
    # infrastructure. This model captures execution metadata, file download arrays, and status 
    # loops directly as strings streamed back from Shopify's API.
    #
    # == Lifecycle Integration
    # This resource encapsulates its GraphQL representation layouts natively via 
    # +XEngine::Shopify::HasGraphQLRepresentation+. Polling query configurations 
    # are declared using the core framework macro layer mapping straight to global nodes.
    #
    class BulkOperation < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Binds endpoints, custom selection fragments, and default pipeline filters.
      # Maps straight to the global node lookup strategy to fetch operations by their graph IDs.
      expose_graphql single: :node, multiple: :bulk_operations do
        <<~GRAPHQL
          __typename
          id
          status
          error_code: errorCode
          created_at: createdAt
          completed_at: completedAt
          object_count: objectCount
          root_object_count: rootObjectCount
          file_size: fileSize
          download_url: url
          partial_data_url: partialDataUrl
          query
        GRAPHQL
      end

      # ---
      # :section: Attribute Accessors
      # ---
      
      # Temporary parameters utilized during runtime mutation generation phases.
      # These live in memory only and are not persisted to database columns.
      attr_accessor :object_type, :filters

      # ---
      # :section: Associations
      # ---

      # The parent store tenant owning the execution context for this asynchronous operation pool.
      belongs_to :shop,
                 class_name: "XEngine::Shopify::Shop",
                 foreign_key: :shop_id,
                 inverse_of: :bulk_operations

      # ---
      # :section: Validations
      # ---

      validates :shop, presence: true
      validates :shopify_id, presence: true, uniqueness: true
      validates :query, presence: true

    end
  end
end
# :startdoc: