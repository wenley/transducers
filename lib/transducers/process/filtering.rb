module Transducers
  class Process
    def filtering(&predicate)
      Process.new(
        init: init,
        step: proc { |collection, value| if yield(value) then step.call(collection, value) else collection end },
        completion: completion,
      )
    end
  end
end
