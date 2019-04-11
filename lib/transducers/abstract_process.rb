require 'lib/transducers/process'

module Transducers
  class AbstractProcess
    def initialize(steps = [])
      @steps = steps
    end
    attr_reader :steps

    def respond_to?(method_name, include_all=false)
      if Process.instance_methods.include?(method_name)
        true
      else
        super
      end
    end

    def method_missing(method_name, *args, &block)
      if Process.instance_methods.include?(method_name)
        AbstractProcess.new(@steps << [method_name, args, block])
      else
        super
      end
    end

    def then(inner_process)
      case inner_process
      when AbstractProcess
        AbstractProcess.new(@steps + inner_process.steps)
      when Process
        @steps.reverse.reduce(inner_process) do |process, (method, args, block)|
          process.send(method, *args, &block)
        end
      end
    end
  end
end
