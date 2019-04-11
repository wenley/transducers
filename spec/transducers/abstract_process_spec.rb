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
  end
end
