require 'lib/core_ext/enumerable'
require 'lib/core_ext/array'
require 'lib/core_ext/hash'

describe Enumerable do
  let(:complex_abstract_process) do
    Transducers::AbstractProcess.new.
      filtering { |v| v % 2 == 0 }.
      mapping { |v| v + 1 }.
      filtering { |v| v % 3 == 0 }
  end

  describe Array do
    describe '#transduce' do
      subject { input_array.transduce(abstract_process, base_process) }
      let(:base_process) do
        Transducers::Process.new(
          init: proc { seed },
          step: step_function,
        )
      end
      let(:input_array) { [1,2,3,4,5,6,7,8] }
      let(:seed) { double }
      let(:step_function) { instance_double(Proc) }
      let(:abstract_process) { Transducers::AbstractProcess.new }

      before do
        allow(step_function).to receive(:call)
      end

      context 'with a simple process' do
        it 'traverses the original array' do
          input_array.each do |value|
            expect(step_function).to receive(:call).with(seed, value).and_return(seed)
          end

          subject
        end

        context 'with a reduced value' do
        end
      end

      context 'with a real process' do
        let(:abstract_process) { complex_abstract_process }

        it 'preprocesses before stepping' do
          expect(step_function).to receive(:call).with(seed, 3).and_return(seed)
          expect(step_function).to receive(:call).with(seed, 9).and_return(seed)
          subject
        end
      end
    end

    describe 'packing as output' do
      subject { (0..9).to_a.transduce(abstract_process, Array.base_process) }

      let(:abstract_process) { complex_abstract_process }

      it 'packs into an array' do
        expect(subject).to eq([3, 9])
      end
    end
  end
end
