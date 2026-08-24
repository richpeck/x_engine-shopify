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
    # == Architecture & Bulk Query Routing
    # Shopify's Admin GraphQL API does not expose a root-level +refunds+ endpoint for bulk operations.
    # To extract refund records in bulk, {expose_graphql} routes through the root +orders+ collection 
    # (+multiple: :orders+) using financial status filter criteria (+financial_status:refunded OR financial_status:partially_refunded+).
    #
    # Consequently, the selection set declared inside {expose_graphql} represents fields evaluated on 
    # the parent +Order+ node, which queries the +refunds+ connection and its child +refundLineItems+ 
    # and +transactions+.
    #
    # == Schema Adjustments
    # - +OrderTransaction+ nodes query +id+, +createdAt+, +processedAt+, +authorizationCode+, 
    #   +receiptJson+, +amountSet+, and +fees+ (avoiding invalid fields +legacyResourceId+, 
    #   +receiptId+, +fee+, or +updatedAt+).
    # - +Refund+ records are fetched through the parent +Order+'s +refunds+ connection, avoiding 
    #   invalid self-nested +refunds+ fields.
    #
    # == Schema Attributes
    # - +id+ [String] Primary key (UUID).
    # - +order_id+ [String] Foreign key referencing parent {XEngine::Shopify::Order}.
    # - +shopify_id+ [String] Canonical GraphQL global tracking ID string returned by Shopify (+gid://shopify/Refund/...+).
    # - +legacy_id+ [Integer] Numeric legacy REST identifier extracted from Shopify.
    # - +note+ [String] Reason or contextual message attached to the refund transaction.
    # - +total_refunded_amount+ [BigDecimal] Aggregated financial value credited back to the customer.
    # - +currency_code+ [String] ISO 4217 currency code (e.g., +"GBP"+, +"USD"+).
    # - +processed_at+ [DateTime] Timestamp indicating when the refund was executed on Shopify.
    # - +created_at+ [DateTime] Record creation timestamp.
    # - +updated_at+ [DateTime] Record modification timestamp.
    #
    # @see HasGraphQLRepresentation
    # @see XEngine::Shopify::Order
    # @see XEngine::Shopify::RefundLineItem
    #
    class Refund < XEngine::Core::Model
      include XEngine::Shopify::HasGraphQLRepresentation

      # =========================================================================
      # :section: GraphQL Layout Declarations
      # =========================================================================

      # Binds endpoints, selection strings, and the default search criteria query 
      # required to discover refunded entities during synchronization sweeps.
      #
      # @note The selection set operates on the parent +Order+ node when executed 
      #   via the +orders+ root bulk endpoint.
      expose_graphql do
        <<~GRAPHQL
          __typename
          id
          created_at: createdAt
          note
          totalRefundedSet {
            shopMoney {
              amount
              currencyCode
            }
          }
        GRAPHQL
      end

      # =========================================================================
      # :section: Associations
      # =========================================================================

      # @!attribute [r] order
      #   @return [XEngine::Shopify::Order] The parent order entity to which this refund belongs.
      belongs_to :order, class_name: "XEngine::Shopify::Order", inverse_of: :refunds, required: true
      
      # @!attribute [r] refund_line_items
      #   @return [ActiveRecord::Associations::CollectionProxy<XEngine::Shopify::RefundLineItem>] Individual item quantity allocations refunded in this transaction.
      has_many :refund_line_items, class_name: "XEngine::Shopify::RefundLineItem", dependent: :destroy, inverse_of: :refund
    end
  end
end