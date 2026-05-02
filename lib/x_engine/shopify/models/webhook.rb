module XEngine
  module Shopify
    class Webhook < XEngine::Core::Model
      # DSL Declarations
      excluded_attributes :secret_key, :shopify_webhook_id
      
      # Expose the POST endpoint for Shopify to hit
      # Route: POST /shopify/webhooks/:id
      expose_as :webhooks, actions: [:create] 

    end
  end
end