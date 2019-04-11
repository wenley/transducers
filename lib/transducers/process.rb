
# Problem with this implementation:
# - Can't start building a process until you have a base process to build on top of
# - Function composition starts at the bottom of the stack
module Transducers
  class Process
    def initialize(init:, step:, completion: nil)
      @init = init
      @step = step
      @completion = completion || DEFAULT_COMPLETION
    end
    attr_reader :init, :step, :completion

    class AbstractProcess
      def initialize
        @steps = []
      end

      def respond_to?(method_name, args)
      end

      def method_missing(method_name, *args, &block)
        if Process.instance_methods.include?(method_name)
          @steps << [method_name, args, block]
        else
          super
        end
      end

      def into(base_process)
        @steps.reversed.reduce(base_process) do |process, (method, args, block)|
          process.send(method, *args, &block)
        end
      end
    end

    DEFAULT_COMPLETION = proc { |value| value }

    def mapping(&operation)
      Process.new(
        init: init,
        step: proc { |collection, value| step.call(collection, yield(value)) },
        completion: completion,
      )
    end

    def filtering(&predicate)
      Process.new(
        init: init,
        step: proc { |collection, value| if yield(value) then step.call(collection, value) else collection end },
        completion: completion,
      )
    end

    def taking(amount)
      Process.new(
        init: proc do
          {
            inner_result: init.call,
            count: 0,
          }
        end,
        step: proc do |result, value|
          if result[:count] > amount
            ReducedValue.new(result[:inner_result])
          else
            {
              inner_result: step.call(result[:inner_result], value),
              count: result[:count] + 1,
            }
          end
        end,
        completion: completion,
      )
    end

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
