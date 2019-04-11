module Transducers
  class Process
    def flattening(level = nil)
      next_step = proc do |collection, value|
        if value.methods.include?(:transduce)
          if level.nil?
            inner_process = AbstractProcess.new.flattening
          elsif level <= 1
            inner_process = AbstractProcess.new
          else
            inner_process = AbstractProcess.new.flattening(level - 1)
          end

          value.transduce(
            inner_process,
            Process.new(
              init: proc { collection },
              step: proc { |_, v| step.call(collection, v) },
            ),
          )
        elsif value.is_a?(Enumerable)
          value.reduce(collection) do |coll, v|
            step.call(coll, v)
          end
        else
          step.call(collection, value)
        end
      end

      Process.new(
        init: init,
        step: next_step,
        completion: completion,
      )
    end
  end
end
