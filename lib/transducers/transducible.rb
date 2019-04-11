require 'lib/transducers/process'
require 'lib/transducers/reduced_value'

module Transducers
  # To be included on Transducible types
  module Transducible
    def transduce(abstract_process, seed: nil, output_class: nil, step_function: nil)
      output_class ||= self.class
      default_base_process = output_class.base_process

      base_process = Process.new(
        init: if seed then proc { seed } else default_base_process.init end,
        step: step_function || default_base_process.step,
        completion: default_base_process.completion || Process::DEFAULT_COMPLETION,
      )

      process = abstract_process.then(base_process)

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

      process.completion.call(final_result)
    end

    def self.base_process
      raise NotImplementedError
    end
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

  class Observable
    # Cannot transduce to other types because of the Async nature of Observables
    # Won't know inner/base process until Observable is subscribed to
    def transduce(abstract_process)
      AnonymousObservable.new do |observer|
        wrapped_observer = Observable.process_to_observer(
          abstract_process.then(
            Observable.observer_to_process(observer),
          ),
          on_error: observer.on_error,
        )

        subscribe(wrapped_observer)
      end
    end

    def to_a2
      subscribe(Observable.process_to_observer(Array.base_process))
    end

    def self.observer_to_process(observer)
      Transducers::Process.new(
        init: proc { observer },
        step: proc do |observer, value|
          begin
            observer.on_next(value)
            observer
          rescue => e
            observer.on_error(e)
            observer
          end
        end,
        completion: proc { |observer| observer.on_completed },
      )
    end

    def self.process_to_observer(process, on_error: nil)
      Observer.configure do |o|
        o.on_next(&process.step)
        o.on_error(&on_error) if on_error
        o.on_completed(&process.completion)
      end
    end
  end
end
