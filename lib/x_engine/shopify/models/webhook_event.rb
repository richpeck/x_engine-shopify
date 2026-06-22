# :stopdoc:
################################################################
################################################################
##   ___       __   _______   ________  ___  ___  ________  ________  ___  __       
##  |\  \     |\  \|\  ___ \ |\   __  \|\  \|\  \|\   __  \|\   __  \|\  \|\  \     
##  \ \  \    \ \  \ \   __/|\ \  \|\ /\ \  \\\  \ \  \|\  \ \  \|\  \ \  \/  /|_   
##   \ \  \  __\ \  \ \  \_|/_\ \   __  \ \   __  \ \  \\\  \ \  \\\  \ \   ___  \  
##    \ \  \|\__\_\  \ \  \_|\ \ \  \|\  \ \  \ \  \ \  \\\  \ \  \\\  \ \  \\ \  \ 
##     \ \____________\ \_______\ \_______\ \__\ \__\ \_______\ \_______\ \__\\ \__\
##      \|____________|\|_______|\|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|
##  --
##  RPECK 22/06/2026 - Shopify Webhook Event Model
##  Captures immutable transactional records of incoming webhook hits
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify Webhook Event
    #
    # An immutable transactional append-log capturing un-manipulated JSON payloads 
    # hitting the system ingress network layer. Tracks execution and stack failure telemetry.
    #
    # == Component Footprint
    # * *Namespace:* +:shopify+
    # * *Resource:* +:webhook_event+
    #
    class WebhookEvent < XEngine::Core::Model
      
      belongs_to :webhook_subscription,
                 class_name: "XEngine::Shopify::WebhookSubscription"

      # Expose resource parameters safely to the global framework schema registry layout
      expose_as :webhook_events,
                identity: :id,
                internal: true,
                actions: [:read]

      attribute :shopify_event_id,  type: :string,  filterable: true
      attribute :shop_domain,       type: :string,  sortable: true, filterable: true
      attribute :topic,             type: :string,  sortable: true, filterable: true
      attribute :payload,           type: :jsonb
      attribute :processing_status, type: :string,  sortable: true, filterable: true
      attribute :processing_error,  type: :text

      # Compiles a structured contextual display string safe for console outputs and admin streams.
      #
      # === Returns
      # * +String+
      #
      def sequence_label
        "[#{created_at.strftime('%Y-%m-%d %H:%M:%S')}] #{shop_domain} -> #{topic} (#{processing_status})"
      end

    end
  end
end
# :startdoc: