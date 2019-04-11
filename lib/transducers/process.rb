require 'lib/transducers/process/dropping_while'
require 'lib/transducers/process/mapping'
require 'lib/transducers/process/filtering'
require 'lib/transducers/process/slicing'
require 'lib/transducers/process/taking'
require 'lib/transducers/process/taking_while'

# Problem with this implementation:
# - Can't start building a process until you have a base process to build on top of
# - Function composition starts at the bottom of the stack
module Transducers
  class Process
    DEFAULT_COMPLETION = proc { |value| value }

    def initialize(init:, step:, completion: nil)
      @init = init
      @step = step
      @completion = completion || DEFAULT_COMPLETION
    end
    attr_reader :init, :step, :completion
  end
end
