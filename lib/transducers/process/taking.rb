module Transducers
  class Process
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
  end
end
