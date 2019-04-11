module Transducers
  class Process
    def taking_while(&predicate)
      Process.new(
        init: init,
        step: proc do |collection, value|
          if yield(value)
            step.call(collection, value)
          else
            ReducedValue.new(collection)
          end
        end,
        completion: completion,
      )
    end
  end
end
