module Transducers
  class Process
    def slicing(slice_size)
      new_completion = proc do |result|
        if result[:wip].count > 0
          inner_result = step.call(result[:inner_result], result[:wip])
        else
          inner_result = result[:inner_result]
        end
        completion.call(inner_result)
      end

      new_step = proc do |result, value|
        result[:wip] << value

        if result[:wip].count == slice_size
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
  end
end
