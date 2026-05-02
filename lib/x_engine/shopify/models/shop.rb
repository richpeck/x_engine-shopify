# :stopdoc:
################################################################
################################################################
##   ________  ___  ___  ________  ________   
##  |\   ____\|\  \|\  \|\   __  \|\   __  \  
##  \ \  \___|\ \  \\\  \ \  \|\  \ \  \|\  \ 
##   \ \_____  \ \   __  \ \  \\\  \ \   ____\
##    \|____|\  \ \  \ \  \ \  \\\  \ \  \___|
##      ____\_\  \ \__\ \__\ \_______\ \__\   
##     |\_________\|__|\|__|\|_______|\|__|   
##     \|_________|                                                      
##  --
##  RPECK 23/04/2026 - Shop
##  Model used to manage the shop objects inside the Shopify context
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # == Shopify Shop
    #
    # Represents a Shopify Store. This model uses the "handle" (subdomain) 
    # as its primary public identity for clean, readable routing.
    #
    class Shop < XEngine::Core::Model
      
      # ---
      # :section: Stackable Configuration
      # ---

      # Expose the shop using its handle (e.g. /shopify/garrys-glasses)
      expose_as :shops, 
                identity: :handle,
                actions: [:read, :update],
                member_actions: { refresh_token: :post }

    end
  end
end