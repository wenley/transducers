module Enumerable
  def transduce(abstract_process, base_process)
    process = abstract_process.then(base_process)

    result = process.init.call

    self.each do |value|
      break if result.is_a?(ReducedValue)
      result = process.step.call(result, value)
    end

    if result.is_a?(ReducedValue)
      final_result = result.value
    else
      final_result = result
    end

    process.completion.call(final_result)
  end
end
