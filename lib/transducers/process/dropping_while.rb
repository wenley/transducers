module Transducers
  class Process
    def dropping_while(&predicate)
      Process.new(
        completion: proc { |result| result[:inner_result] },
        step: proc do |result, value|
          if yield(value) && result[:dropping]
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
