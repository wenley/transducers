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
          if result[:count] <= amount
            next_result = step.call(result[:inner_result], value)
          else
            next_result = result
          end

          new_count = result[:count] + 1

          if new_count >= amount
            ReducedValue.new(result[:inner_result])
          else
            {
              inner_result: next_result,
              count: new_count,
            }
          end
        end,
        completion: completion,
      )
    end
  end
end
