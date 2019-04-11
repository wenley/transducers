require './process'
require './reduced_value'

module Transducers
  # To be included on Transducible types
  module Transducible
    def transduce(abstract_process, seed: nil, output_class: nil, step_function: nil)
      output_class ||= self.class
      default_base_process = output_class.base_process

      base_process = Process.new(
        init: seed || default_base_process.init,
        step: step_function || default_base_process.step,
        completion: completion_function || default_base_process.completion,
      )

      process = abstract_process.into(base_process)

      result = process.init.call

      if self.is_a?(Enumerable) || self.public_methods.include?(:each)
        self.each do |value|
          break if result.is_a?(ReducedValue)
          result = process.step.call(result, value)
        end
      else
        raise "Don't know how to traverse a #{self.class}"
      end

      if result.is_a?(ReducedValue)
        final_result = result.value
      else
        final_result = result
      end

      process.complete(final_result)
    end

    def self.base_process
      raise NotImplementedError
    end
  end
end

class Array
  include Transducers::Transducible

  def self.base_process
    Transducers::Process.new(
      init: method(:new),
      step: proc { |array, value| array << value },
    )
  end
end

class Hash
  include Transducers::Transducible

  def self.base_process
    Transducers::Process.new(
      init: method(:new),
      step: proc { |hash, (key, value)| hash[key] = value; hash },
    )
  end
end

module Rx
  class Subject
    include Transducers::Transducible

    def self.base_process
      Transducers::Process.new(
        init: method(:new),
        step: proc { |subject, value| subject.on_next(value); subject },
        completion: proc { |subject| subject.on_completed },
      )
    end
  end
end
