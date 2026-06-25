# :stopdoc:
################################################################
################################################################
##   ________  ________  ___  ___  _________  _______   ________      
##  |\   __  \|\   __  \|\  \|\  \|\___   ___\\  ___ \ |\   ____\     
##  \ \  \|\  \ \  \|\  \ \  \\\  \|___ \  \_\ \   __/|\ \  \___|_    
##   \ \   _  _\ \  \\\  \ \  \\\  \   \ \  \ \ \  \_|/_\ \_____  \   
##    \ \  \\  \\ \  \\\  \ \  \\\  \   \ \  \ \ \  \_|\ \|____|\  \  
##     \ \__\\ _\\ \_______\ \_______\   \ \__\ \ \_______\____\_\  \ 
##      \|__|\|__|\|_______|\|_______|    \|__|  \|_______|\_________\
##                                                        \|_________|
##  --
##  RPECK 12/06/2026 - Client API Engine Wrapper
##  Manages Shopify configuration boundaries and credentials context
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

# = XEngine Shopify Extension Routing Interface Configuration
#
# Formulates and appends the Shopify integration engine API boundaries directly onto
# the shared application network architecture. Endpoints declared here are isolated 
# from parent domain constraints, processing inbound webhooks and data syncs relatively.
#
# == Mounting Footprint
# This routing matrix does not declare hardcoded application API prefixes or nested 
# tenancy pathing filters. It relies completely on the parent application's Rack setup
# to anchor this entire extension segment smoothly onto the global path infrastructure.
#
XEngine::Application["web.router"].draw do

  # Encapsulates the multi-tenant context inside a standardized RESTful resource block.
  # This maps the root token parameter as +:shopify_id+ (representing the target shop's identifier).
  #
  resources :shopify do

    # Dynamic resource mappings leveraging nested routing architecture.
    # Yields resource access paths isolated securely per tenant record structure:
    # e.g., GET /shopify/:shopify_id/orders -> orders.index
    resources :orders, only: [:index, :show]

  end
end
# :startdoc: