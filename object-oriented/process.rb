
# Problem with this implementation:
# - Can't start building a process until you have a base process to build on top of
# - Function composition starts at the bottom of the stack
class Process
  def initialize(completion: nil, step:, init:, inner_process:)
    @step = step
    @init = init
    @completion = completion || DEFAULT_COMPLETION
    @inner_process = inner_process
  end
  attr_reader :completion, :step, :init, :inner_process

  include ExtendibleProcess

  # Placeholder for
  class BaseProcess
    def initialize
      @step = nil
      @init = nil
      @completion = DEFAULT_COMPLETION
    end
    attr_reader :completion, :step, :init

    include ExtendibleProcess

    def apply_to(seed:, step_function:, outermost: true)
      self.init = proc { seed }
      self.step = step_function

      if outermost
        return ConcreteProcess(self)
      end
    end
  end

  class ConcreteProcess
    def initialize(process)
      @step = process.step
      @init = process.init
      @completion = process.completion || DEFAULT_COMPLETION
    end
    attr_reader :completion, :step, :init

    def apply

    end
  end

  def self.base_process

  end

  def apply_to(seed:, step_function:, outermost: true)
    inner_class.apply_to(seed: seed, step_function: step_function, outermost: false)

    if outermost
      return ConcreteProcess(self)
    end
  end

  DEFAULT_COMPLETION = proc { |value| value }

  module ExtendibleProcess
    def mapping(&operation)
      Process.new(
        completion: completion,
        step: proc { |collection, value| step.call(collection, yield(value)) },
      )
    end

    def filtering(&predicate)
      Process.new(
        completion: completion,
        step: proc { |collection, value| if yield(value) then step.call(collection, value) else collection end },
      )
    end

    def taking(amount)
      Process.new(
        completion: completion,
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
        init: proc do
          {
            inner_result: init.call,
            count: 0,
          }
        end,
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
