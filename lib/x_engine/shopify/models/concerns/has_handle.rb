# :stopdoc:
################################################################
################################################################
##  ___  ___  ________  ________   ________  ___       _______      
## |\  \|\  \|\   __  \|\   ___  \|\   ___ \|\  \     |\  ___ \     
## \ \  \\\  \ \  \|\  \ \  \\ \  \ \  \_|\ \ \  \    \ \   __/|    
##  \ \   __  \ \   __  \ \  \\ \  \ \  \ \\ \ \  \    \ \  \_|/__  
##   \ \  \ \  \ \  \ \  \ \  \\ \  \ \  \_\\ \ \  \____\ \  \_|\ \ 
##    \ \__\ \__\ \__\ \__\ \__\\ \__\ \_______\ \_______\ \_______\
##     \|__|\|__|\|__|\|__|\|__| \|__|\|_______|\|_______|\|_______|
##                                                                   
##  --
##  RPECK 20/06/2026 - HasHandle Extension Concern
##  Provides automated, configurable string normalization for Shopify resource slugs.
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Shopify
    # = Shopify HasHandle Concern
    #
    # Mixin module providing standard regex normalization and url-safe handle compilation
    # specifically tailored for Shopify ecosystem domain resources.
    #
    # == Usage
    #
    #   class Tag < XEngine::Core::Model
    #     include XEngine::Shopify::HasHandle
    #
    #     # Automatically tracks and normalizes the :title column into the :handle column
    #     has_handle :title
    #   end
    #
    module HasHandle
      extend ActiveSupport::Concern

      class_methods do
        # Registers a lifecycle routine to generate a url-safe slug before saving the model state.
        #
        # === Parameters
        # * +source_field+ [+Symbol+] - The attribute to clean and normalize. Defaults to +:title+.
        #
        # @return [void]
        def has_handle(source_field = :title)
          before_save -> { generate_handle_from(source_field) }
        end
      end

      private

      # Sanitizes the value of the targeted source attribute into a standardized slug format.
      # Updates the model's +handle+ property inline.
      #
      # @return [void]
      def generate_handle_from(source_field)
        source_value = public_send(source_field)
        return unless source_value.present?

        self.handle = source_value
                      .to_s
                      .downcase
                      .strip
                      .gsub(/\s+/, "-")
                      .gsub(/[^\w\-]+/, "")
                      .gsub(/-+/, "-")
      end
    end
  end
end