require 'lib/transducers/process/mapping'
require 'lib/transducers/process/filtering'
require 'lib/transducers/process/taking'

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

    def taking_while(&predicate)
      Process.new(
        completion: completion,
        step: proc do |collection, value|
          if yield(value)
            step.call(collection, value)
          else
            ReducedValue.new(collection)
          end
        end,
      )
    end

    def slicing(slice_size)
      new_completion = proc do |result|
        if state[:wip].count > 0
          inner_result = step.call(result[:inner_result], state[:wip])
        else
          inner_result = result[:inner_result]
        end
        completion.call(inner_result)
      end

      new_step = proc do |result, value|
        result[:wip] << value

        if state[:wip].count == slice_size
          {
            inner_result: step.call(result[:inner_result], result[:wip]),
            wip: [],
          }
        else
          result
        end
      end

      Process.new(
        init: proc { { inner_result: init.call, wip: [] } },
        step: new_step,
        completion: new_completion,
      )
    end

    def dropping_while(&predicate)
      Process.new(
        completion: completion,
        step: proc do |result, value|
          if yield(value) && state[:dropping]
            result
          else
            {
              inner_result: step.call(result[:inner_result], value),
              dropping: false,
            }
          end
        end,
        init: proc { { inner_result: init.call, dropping: true } },
      )
    end
  end
end
