# To be included on Transducible types
module Transducible
  def transduce(process, seed: nil, output_class: nil, step_function: nil)
    output_class ||= self.class
    seed ||= output_class.default_seed
    step_function ||= seed.method(:step)

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

  def default_seed
    raise NotImplementedError
  end

  def step(result, value)
    raise NotImplementedError
  end
end

class Array
  include Transducible

  def default_seed
    []
  end

  def step(prev_array, value)
    prev_array << value
  end
end

class Hash
  include Transducible

  def default_seed
    {}
  end

  def step(prev_hash, key_value_pair)
    key, value = key_value_pair

    prev_hash[key] = value

    prev_hash
  end
end
