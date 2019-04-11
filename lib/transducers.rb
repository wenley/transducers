
# Require all of the Ruby files in the given directory.
#
# path - The String relative path from here to the directory.
#
# Returns nothing.
def require_all(path)
  glob = File.join(File.dirname(__FILE__), path, '*.rb')
  Dir[glob].sort.each do |f|
    require f
  end
end

require 'transducers/reduced_value'
require 'transducers/process'
require 'transducers/abstract_process'
require_all 'transducers/process'
require 'transducers'
