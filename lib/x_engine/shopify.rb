################################################################
################################################################
##   ___    ___      _______   ________   ________  ___  ________   _______           ________  _____ ______   _________  ________   
##  |\  \  /  /|    |\  ___ \ |\   ___  \|\   ____\|\  \|\   ___  \|\  ___ \         |\   ____\|\   _ \  _   \|\___   ___\\   __  \  
##  \ \  \/  / /    \ \   __/|\ \  \\ \  \ \  \___|\ \  \ \  \\ \  \ \   __/|        \ \  \___|\ \  \\\__\ \  \|___ \  \_\ \  \|\  \ 
##   \ \    / /      \ \  \_|/_\ \  \\ \  \ \  \  __\ \  \ \  \\ \  \ \  \_|/__       \ \_____  \ \  \\|__| \  \   \ \  \ \ \   ____\
##    /     \/        \ \  \_|\ \ \  \\ \  \ \  \|\  \ \  \ \  \\ \  \ \  \_|\ \       \|____|\  \ \  \    \ \  \   \ \  \ \ \  \___|
##   /  /\   \         \ \_______\ \__\\ \__\ \_______\ \__\ \__\\ \__\ \_______\        ____\_\  \ \__\    \ \__\   \ \__\ \ \__\   
##  /__/ /\ __\         \|_______|\|__| \|__|\|_______|\|__|\|__| \|__|\|_______|       |\_________\|__|     \|__|    \|__|  \|__|   
##  |__|/ \|__|                                                                         \|_________|                                 
##  --
##  RPECK 22/04/2026 - XEngine SMTP
##  Used to provide the means to enhance the underlying system/engine so that the system can be stacked atop it
################################################################
################################################################

# frozen_string_literal: true

## RPECK 22/04/2026 - Libraries
require "zeitwerk"

module XEngine
  module SMTP
    def self.migrations_path
      File.expand_path('smtp/db/migrate', __dir__)
    end
  end
end

# Register with XEngine Core if available
if defined?(XEngine::Database)
  XEngine::Database.extension_migration_paths << XEngine::SMTP.migrations_path
end

if defined?(XEngine::Repository)
  XEngine::Repository.register_node(:smtp_send, XEngine::SMTP::SendEmailNode)
end
