require 'lib/transducers/process'

describe Transducers::Process do
  let(:init) { instance_double(Proc) }
  let(:step) { instance_double(Proc) }
  let(:completion) { instance_double(Proc) }

  context 'without an init' do
    subject { described_class.new(step: step) }

    it 'raises' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  context 'without a step' do
    subject { described_class.new(init: init) }

    it 'raises' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  context 'without a completion' do
    subject { described_class.new(init: init, step: step) }

    it 'uses the default' do
      expect { subject }.to_not raise_error
      expect(subject.completion).to eq(described_class::DEFAULT_COMPLETION)
    end
  end
end
