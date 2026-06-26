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

module XEngine
  module Shopify
    module Web
      class Routes < XEngine::Core::Web::Routes
        routes do
          # The routing definitions run inside Hanami's execution scope.
          # Strings look up directly through dry-system via our master compiler's resolver.
          get "/hello", to: ->(env) { [200, {}, ["Welcome to Hanami!"]] }
        end
      end
    end
  end
end
# :startdoc: