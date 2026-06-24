# :stopdoc:
################################################################
################################################################
##  ________  _______   ________ ___  ___  ________   ________  
## |\   __  \|\  ___ \ |\  _____\\  \|\  \|\   ___  \|\   ___ \ 
## \ \  \|\  \ \   __/|\ \  \__/\ \  \\\  \ \  \\ \  \ \  \_|\ \
##  \ \   _  _\ \  \_|/_\ \   __\\ \  \\\  \ \  \\ \  \ \  \ \\ \
##   \ \  \\  \\ \  \_|\ \ \  \_| \ \  \\\  \ \  \\ \  \ \  \_\\ \
##    \ \__\\ _\\ \_______\ \__\   \ \_______\ \__\\ \__\ \_______\
##     \|__|\|__| \|_______|\|__|    \|_______|\|__| \|__|\|_______|
##                                                                  
##  --
##  RPECK 24/06/2026 - Refund Object
##  Provides the means to track and record financial refunds within the ecosystem.
##  --
##  Ref: https://shopify.dev/docs/api/admin-graphql/2024-01/objects/Refund
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Refund Model
    #
    # Records and tracks financial order ledger rollbacks inside the system. 
    # Maps distinct line item allocations alongside transaction note contexts.
    #
    # == Lifecycle Integration
    # This resource encapsulates its GraphQL representation layouts natively via 
    # {XEngine::Shopify::HasGraphQLRepresentation}. It queries the 'orders' endpoint 
    # using strict financial status parameters to fetch only refunded records.
    #
    class Refund < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # Registers the class context as an active shopify resource entity layer
      expose_as :shopify, :refund

      # == GraphQL Layout Declarations
      # Binds endpoints, selection strings, and the default search criteria query 
      # required to discover refunded entities during synchronization sweeps.
      expose_graphql single: :order, 
                     multiple: :orders, 
                     default_filter: "financial_status:refunded OR financial_status:partially_refunded" do
        <<~GRAPHQL
          __typename
          id
          legacy_id: legacyResourceId
          refunds {
            id: legacyResourceId
            note
            created_at: createdAt
            value: totalRefunded {
              amount
              currencyCode
            } 
          }
        GRAPHQL
      end

      # == Associations
      # Structural boundaries tying transaction line item states to underlying entities
      belongs_to :order, class_name: "XEngine::Shopify::Order", inverse_of: :refunds, required: true
      
      has_many :refund_line_items, class_name: "XEngine::Shopify::RefundLineItem", dependent: :destroy, inverse_of: :refund
    end
  end
end
# :startdoc: