require 'lib/transducers/process'

describe Transducers::Process do
  let(:base_process) { described_class.new(init: init, step: step, completion: completion) }
  let(:init) { instance_double(Proc) }
  let(:step) { instance_double(Proc) }
  let(:completion) { instance_double(Proc) }

  describe '#slicing' do
    let(:process) { base_process.slicing(slice_size) }

    let(:inner_result) { double }
    let(:slice_size) { 2 }

    subject do
      final_result = values.reduce(process.init.call, &process.step)
      process.completion.call(final_result)
    end

    before do
      allow(init).to receive(:call).and_return(inner_result)
      allow(completion).to receive(:call).with(inner_result).and_return(inner_result)
    end

    context 'exact multiple of the slice size' do
      let(:values) { 1..4 }

      it 'bundles' do
        expect(step).to receive(:call).with(inner_result, [1, 2]).and_return(inner_result)
        expect(step).to receive(:call).with(inner_result, [3, 4]).and_return(inner_result)

        subject
      end
    end

    context 'fewer than the limit' do
      let(:slice_size) { 5 }
      let(:values) { 1..3 }

      it 'still passes the values collected' do
        expect(step).to receive(:call).with(inner_result, [1,2,3]).and_return(inner_result)
        subject
      end
    end

    context 'with an uneven number of values' do
      let(:values) { 1..3 }

      it 'bundles' do
        expect(step).to receive(:call).with(inner_result, [1, 2]).and_return(inner_result)
        expect(step).to receive(:call).with(inner_result, [3]).and_return(inner_result)

        subject
      end
    end
  end
end
