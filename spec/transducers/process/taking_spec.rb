require 'lib/transducers/process'

describe Transducers::Process do
  let(:base_process) { described_class.new(init: init, step: step, completion: completion) }
  let(:init) { instance_double(Proc) }
  let(:step) { instance_double(Proc) }
  let(:completion) { instance_double(Proc) }

  describe '#taking' do
    let(:process) { base_process.taking(2) }

    let(:inner_result) { double }
    let(:value) { double }

    before do
      allow(init).to receive(:call).and_return(inner_result)
      allow(step).to receive(:call).with(inner_result, value).and_return(inner_result)
    end

    it 'pass through until count met' do
      expect(step).to receive(:call).with(inner_result, value)
        .exactly(2).times
        .and_return(inner_result)

      result = process.init.call
      expect(result).to_not be_a(ReducedValue)

      result = process.step.call(result, value)
      expect(result).to_not be_a(ReducedValue)

      result = process.step.call(result, value)
      expect(result).to be_a(ReducedValue)
    end
  end
end
