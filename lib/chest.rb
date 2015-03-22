module Chest
  PLUGINS_FOLDER = File.expand_path('~/Library/Containers/com.bohemiancoding.sketch3/Data/Library/Application Support/com.bohemiancoding.sketch3/Plugins')
  MANIFEST_PATH = File.join(PLUGINS_FOLDER, '.manifest.json')
end

require 'chest/version'
require 'chest/config'
require 'chest/manifest'
require 'chest/registry'
require 'chest/plugin'
require 'chest/cli'
