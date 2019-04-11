module Transducers
  class Process
    def mapping(&operation)
      Process.new(
        init: init,
        step: proc { |collection, value| step.call(collection, yield(value)) },
        completion: completion,
      )
    end
  end
end
