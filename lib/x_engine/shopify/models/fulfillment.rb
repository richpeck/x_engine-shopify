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
##  RPECK 22/06/2026 - Shopify Webhook Subscription Model
##  Manages multi-tenant event endpoint routing configurations
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Fulfillment Model
    #
    # Domain entity managing delivery pipelines, dispatch logging, and courier 
    # tracking references for Shopify Orders.
    #
    # == Lifecycle Integration
    # This resource encapsulates its GraphQL representation layouts natively via
    # +XEngine::Shopify::HasGraphQLRepresentation+. Schedules automated logistical 
    # background processing routines when state tracking saves occur.
    #
    class Fulfillment < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # ---
      # :section: Serialization Abstractions
      # ---

      # Handle SQLite3 fallback structural transformations for tracking arrays automatically
      serialize :tracking_numbers, coder: JSON, default: []
      serialize :tracking_urls,    coder: JSON, default: []

      # == GraphQL Layout Declarations
      # Binds delivery status targets, carrier strings, and shipment tracking fields.
      expose_graphql single: :fulfillment, multiple: :fulfillments do
        <<~GRAPHQL
          __typename
          id
          legacy_id: legacyResourceId
          name
          status: displayStatus
          tracking_company: trackingInfo {
            company
          }
          tracking_numbers: trackingInfo {
            number
          }
          tracking_urls: trackingInfo {
            url
          }
          created_at: createdAt
          updated_at: updatedAt
        GRAPHQL
      end

      # ---
      # :section: Associations
      # ---

      # The parent order context tied to this fulfillment sequence.
      belongs_to :order, 
                 foreign_key: :order_id, 
                 class_name: "XEngine::Shopify::Order", 
                 inverse_of: :fulfillments

      # Audit ledger references inherited directly from the companion order sequence.
      has_many :transactions, 
               through: :order, 
               class_name: "XEngine::Shopify::OrderTransaction"

      # ---
      # :section: Validations
      # ---

      validates :order, :status, presence: true
      
    end
  end
end
# :startdoc: