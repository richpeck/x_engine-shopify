# :stopdoc:
################################################################
################################################################
##  ________  ___  ___  ___       ___  __             ________  ________  _______   ________  ________  _________  ___  ________  ________      
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
    class BulkOperation < XEngine::Core::Model

      # ---
      # :section: Stackable Configuration
      # ---

      # Decouple internal keys while exposing a clean 'bulk_operations' path
      expose_as :shopify_bulk_operations,
                slug: :bulk_operations,
                identity: :shopify_id,
                actions: [:read, :create, :destroy], # Swapped :delete to :destroy
                member_actions: { cancel: :post }

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

      # Forward-compatible validation check guarding state accuracy without relying on strict 
      # ActiveRecord enum integer mapping constraints.
      validates :status,
                presence: true,
                inclusion: {
                  in: %w[CREATED RUNNING COMPLETED EXPIRED FAILED CANCELED CANCELING],
                  message: ->(_, data) { "'#{data[:value]}' is not a recognized Shopify bulk infrastructure status." }
                }

      # ---
      # :section: Instance Methods
      # ---

      # Helper check confirming if the dataset payload is completely prepped for file processing.
      # Matches the exact screaming snake case string format returned from Shopify's GraphQL gateway.
      #
      # @return [Boolean]
      def ready_for_download?
        status == "COMPLETED" && download_url.present?
      end

      # Helper check evaluating whether the background job crashed on Shopify's cluster.
      #
      # @return [Boolean]
      def failed?
        status == "FAILED"
      end

    end
  end
end