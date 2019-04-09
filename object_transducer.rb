

module Transducers
  class Process
    def initialize(completion: nil, step:, init:)
      @step = step
      @init = init
      @completion = completion || DEFAULT_COMPLETION
    end
    attr_reader :completion, :step, :init

    DEFAULT_COMPLETION = proc { |value| value }
    DEFAULT_INITIAL_STATE = proc { {} }

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

  # To be included on Transducible types
  module Transducible
    def transduce(process, seed: nil, output_class: nil, step_function: nil)
      output_class ||= self.class
      seed ||= output_class.default_seed
      step_function ||= seed.method(:step)

      result = process.init.call

      process =

      self.each do |value|
        break if result.is_a?(ReducedValue)
        result = process.step.call(result, value)
      end

      if result.is_a?(ReducedValue)
        final_result = result.value
      else
        final_result = result
      end

      process.complete(final_result)
    end

    def default_seed
      raise NotImplementedError
    end

    def step(result, value)
      raise NotImplementedError
    end
  end

  ReducedValue = Struct.new(:value)
end

module Transducible
  def step(collection, value)
    collection
  end

  def default_seed
  end

  def transduce(operation, step_function, seed, input_collection)
    input_collection
  end
end

class Array
  include Transducible

  def step(value)
    self << value
    self
  end

  def self.default_seed
    []
  end

  def transduce(output_transducible_class: nil, seed: nil, step_function: nil, &operation)
    output_transducible_class ||= self.class
    seed ||= output_transducible_class.default_seed
    step_function ||= seed.method(:step)

    state = operation

    self.each do |value|
      yield(value, step_function, state)
    end
  end
end

# Ideal usage:

baggage_process = Transducers.base_process.
  flat_mapping { |pallet| pallet.bags }.
  filtering { |bag| bag.non_food? }.
  mapping { |bag|
    if bag.heavy?
      bag.label += " (heavy)"
    end
    bag
  }
(0..9).to_a.transduce(
