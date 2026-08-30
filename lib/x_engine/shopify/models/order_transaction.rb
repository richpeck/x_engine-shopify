# :stopdoc:
################################################################
################################################################
##   ________  ________  ________  _______   ________          _________  ________  ________  ________   ________  ________  ________ _________  ___  ________  ________   ________      
##  |\   __  \|\   __  \|\   ___ \|\  ___ \ |\   __  \        |\___   ___\\   __  \|\   __  \|\   ___  \|\   ____\|\   __  \|\   ____\\___   ___\\  \|\   __  \|\   ___  \|\   ____\     
##  \ \  \|\  \ \  \|\  \ \  \_|\ \ \   __/|\ \  \|\  \       \|___ \  \_\ \  \|\  \ \  \|\  \ \  \\ \  \ \  \___|\ \  \|\  \ \  \___\|___ \  \_\ \  \ \  \|\  \ \  \\ \  \ \  \___|_    
##   \ \  \\\  \ \   _  _\ \  \ \\ \ \  \_|/_\ \   _  _\           \ \  \ \ \   _  _\ \   __  \ \  \\ \  \ \_____  \ \   __  \ \  \       \ \  \ \ \  \ \  \\\  \ \  \\ \  \ \_____  \   
##    \ \  \\\  \ \  \\  \\ \  \_\\ \ \  \_|\ \ \  \\  \|           \ \  \ \ \  \\  \\ \  \ \  \ \  \\ \  \|____|\  \ \  \ \  \ \  \____   \ \  \ \ \  \ \  \\\  \ \  \\ \  \|____|\  \  
##     \ \_______\ \__\\ _\\ \_______\ \_______\ \__\\ _\            \ \__\ \ \__\\ _\\ \__\ \__\ \__\\ \__\____\_\  \ \__\ \__\ \_______\  \ \__\ \ \__\ \_______\ \__\\ \__\____\_\  \ 
##      \|_______|\|__|\|__|\|_______|\|_______|\|__|\|__|            \|__|  \|__|\|__|\|__|\|__|\|__| \|__|\_________\|__|\|__|\|_______|   \|__|  \|__|\|_______|\|__| \|__|\_________\
##                                                                                                         \|_________|                                                      \|_________|
## --
##  RPECK 09/07/2026 - Shopify Order Transaction Model
##  Domain entity managing settlement states, processing channels, and monetary ledger adjustments.
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Order Transaction Model
    #
    # Domain entity managing payment flows, adjustments, processing fees, and gateway
    # authorizations for order balance states.
    #
    # == Lifecycle Integration
    # This resource encapsulates its GraphQL representation layouts natively via
    # +XEngine::Shopify::HasGraphQLRepresentation+.
    #
    class OrderTransaction < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # == GraphQL Layout Declarations
      # Binds processing categories, gateway states, and financial tracking metrics.
      expose_graphql do
        <<~GRAPHQL
          __typename
          id
          kind
          status
          gateway
          receiptJson
          order {
            id 
          }
          amount: amountSet {
            shopMoney {
              amount
            }
          }
          fees {
              amount {
                  amount
                  currencyCode
              }
              flatFeeName
              rate
              rateName
              taxAmount {
                  amount
                  currencyCode
              }
          }
          created_at: createdAt
        GRAPHQL
      end

      # ---
      # :section: Associations
      # ---

      # The parent order context containing this transactional settlement change.
      belongs_to :order,
                 foreign_key: :order_id,
                 class_name: "XEngine::Shopify::Order",
                 inverse_of: :transactions

      # ---
      # :section: Validations
      # ---

      validates :order, :kind, :status, :amount, presence: true

    end
  end
end
# :startdoc: