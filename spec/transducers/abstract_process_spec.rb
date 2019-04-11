require 'lib/transducers/abstract_process'

describe Transducers::AbstractProcess do
  let(:abstract_process) { described_class.new }

  describe 'storing calls' do
    context 'with a method on Process' do
      subject { abstract_process.mapping(&mapping) }
      let(:mapping) { proc { |v| v + 1 } }

      it 'returns a value' do
        expect { subject }.to_not raise_error
      end

      context 'with improper arguments' do
        let(:mapping) { nil }

        pending 'raises' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with a method not on Process' do
      subject { abstract_process.bad_method(5) }

      it 'raises an error' do
        expect { subject }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#into' do
    subject { abstract_process.into(base_process) }
    let(:base_process) { Transducers::Process.new(init: init, step: step) }
    let(:init) { instance_double(Proc) }
    let(:step) { instance_double(Proc) }

    it 'returns a real process' do
      expect(subject).to be_a(Transducers::Process)
    end

    context 'with operations queued' do
      let(:abstract_process) do
        described_class.new.
          filtering { |v| v % 2 == 0 }.
          mapping { |v| v + 1 }.
          filtering { |v| v % 3 == 0 }
      end
      let(:result) { [] }
      let(:inner_result) { 'aoeu' }

      before do
        allow(step).to receive(:call).with(result, anything).and_return(inner_result)
      end

      it 'performs all the operations' do
        expect(subject.step.call(result, 0)).to eq(result)
        expect(subject.step.call(result, 1)).to eq(result)
        expect(subject.step.call(result, 2)).to eq(inner_result)
        expect(subject.step.call(result, 3)).to eq(result)
        expect(subject.step.call(result, 4)).to eq(result)
        expect(subject.step.call(result, 5)).to eq(result)
        expect(subject.step.call(result, 6)).to eq(result)
        expect(subject.step.call(result, 7)).to eq(result)
        expect(subject.step.call(result, 8)).to eq(inner_result)
      end

      context 'when it should not pass through 'do
        it 'does not' do
          expect(step).to_not receive(:call)
          expect(subject.step.call(result, 0)).to eq(result)
          expect(subject.step.call(result, 1)).to eq(result)
          # expect(subject.step.call(result, 2)).to eq(inner_result)
          expect(subject.step.call(result, 3)).to eq(result)
          expect(subject.step.call(result, 4)).to eq(result)
          expect(subject.step.call(result, 5)).to eq(result)
          expect(subject.step.call(result, 6)).to eq(result)
          expect(subject.step.call(result, 7)).to eq(result)
        end
      end

      context 'when it should pass through' do
        context do
          let(:value) { 2 }

          it 'does' do
            expect(step).to receive(:call).with(result, value + 1).and_return(inner_result)
            expect(subject.step.call(result, value)).to eq(inner_result)
          end
        end

        context do
          let(:value) { 8 }

          it 'does' do
            expect(step).to receive(:call).with(result, value + 1).and_return(inner_result)
            expect(subject.step.call(result, value)).to eq(inner_result)
          end
        end
      end
    end
  end

  describe '#then' do
    subject { first.then(second) }
    let(:first) { described_class.new.mapping { |v| v + 1 } }
    let(:second) { described_class.new.mapping { |v| v + 2 } }
    let(:base_process) { Transducers::Process.new(init: double, step: step) }
    let(:step) { instance_double(Proc) }

    let(:result) { double }
    let(:inner_result) { double }

    it 'composes' do
      expect(step).to receive(:call).with(result, 3).and_return(inner_result)
      expect(subject.into(base_process).step.call(result, 0)).to eq(inner_result)
    end
  end
end
