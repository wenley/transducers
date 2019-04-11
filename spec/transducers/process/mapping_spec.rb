require 'lib/transducers/process'

describe Transducers::Process do
  let(:base_process) { described_class.new(init: init, step: step, completion: completion) }
  let(:init) { instance_double(Proc) }
  let(:step) { instance_double(Proc) }
  let(:completion) { instance_double(Proc) }

  describe '#mapping' do
    let(:process) { base_process.mapping { |val| val + 1 } }

    describe '#step' do
      subject { process.step.call(result, value) }
      let(:result) { [] }
      let(:value) { 1 }

      let(:inner_result) { [1] }

      it 'maps the value' do
        expect(step).to receive(:call).with(result, value + 1).and_return(inner_result)
        expect(subject).to eq(inner_result)
      end
    end
  end
end
