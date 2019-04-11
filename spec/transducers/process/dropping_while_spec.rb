require 'lib/transducers/process'

describe Transducers::Process do
  let(:base_process) { described_class.new(init: init, step: step, completion: completion) }
  let(:init) { instance_double(Proc) }
  let(:step) { instance_double(Proc) }
  let(:completion) { instance_double(Proc) }

  describe '#dropping_while' do
    let(:process) { base_process.dropping_while { |value| value % 2 == 0 } }

    let(:inner_result) { double }

    subject do
      final_result = values.reduce(process.init.call, &process.step)
      process.completion.call(final_result)
    end

    before do
      allow(init).to receive(:call).and_return(inner_result)
      allow(completion).to receive(:call).with(inner_result).and_return(inner_result)
    end

    context 'never breaking the condition' do
      let(:values) { [2,4,6,8] }

      it 'never calls inner step' do
        expect(step).to_not receive(:call)
        subject
      end
    end

    context 'breaking the condition' do
      let(:values) { [2,3,4,5] }

      it 'calls including and after the breaking value' do
        expect(step).to_not receive(:call).with(inner_result, 2)
        (3..5).each do |value|
          expect(step).to receive(:call).with(inner_result, value).and_return(inner_result)
        end

        subject
      end
    end
  end
end
