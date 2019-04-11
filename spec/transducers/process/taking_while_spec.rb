require 'lib/transducers/process'

describe Transducers::Process do
  let(:base_process) { described_class.new(init: init, step: step, completion: completion) }
  let(:init) { instance_double(Proc) }
  let(:step) { instance_double(Proc) }
  let(:completion) { instance_double(Proc) }

  describe '#taking_while' do
    let(:process) { base_process.taking_while { |val| val < 3 } }

    describe '#step' do
      subject { process.step.call(result, value) }
      let(:result) { double }
      let(:inner_result) { double }

      context 'condition not met' do
        let(:value) { 1 }

        it 'passes through' do
          expect(step).to receive(:call).with(result, value).and_return(inner_result)
          expect(subject).to eq(inner_result)
        end
      end

      context 'condition met' do
        let(:value) { 3 }

        it 'marks value as reduced' do
          expect(step).to_not receive(:call)
          expect(subject).to be_a(ReducedValue)
          expect(subject.value).to eq(result)
        end
      end
    end
  end
end
