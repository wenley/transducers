require 'lib/transducers/process'

describe Transducers::Process do
  let(:base_process) { described_class.new(init: init, step: step, completion: completion) }
  let(:init) { instance_double(Proc) }
  let(:step) { instance_double(Proc) }
  let(:completion) { instance_double(Proc) }

  before do
    allow(init).to receive(:call).with(no_args)
  end

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

  describe '#filtering' do
    let(:process) { base_process.filtering { |value| value % 2 == 0 } }

    describe '#step' do
      subject { process.step.call(result, value) }

      let(:result) { [] }
      let(:inner_result) { 'aoeu' }

      context 'value passes the filter' do
        let(:value) { 2 }

        it 'passes through' do
          expect(step).to receive(:call).with(result, value).and_return(inner_result)
          expect(subject).to eq(inner_result)
        end
      end

      context 'value rejected by filter' do
        let(:value) { 3 }

        it 'skips underlying call' do
          expect(step).to_not receive(:call)
          expect(subject).to eq(result)
        end
      end
    end
  end
end
