describe Transducers::Process do
  let(:base_process) { described_class.new(init: init, step: step) }
  let(:init) { instance_double(Proc) }
  let(:step) { instance_double(Proc) }

  describe '#flattening' do
    let(:process) { base_process.flattening }
    let(:values) do
      [
        1,
        2,
        [
          3,
          [
            4,
            [5],
          ],
          6,
        ],
      ]
    end
    let(:inner_result) { double }

    before do
      allow(init).to receive(:call).and_return(inner_result)
    end

    subject do
      final_result = values.reduce(process.init.call, &process.step)
      process.completion.call(final_result)
    end

    context 'without argument' do
      it 'fully flattens' do
        (1..6).each do |num|
          expect(step).to receive(:call).with(inner_result, num).and_return(inner_result)
        end

        expect(subject).to eq(inner_result)
      end
    end

    context 'with integer argument' do
      let(:process) { base_process.flattening(levels) }
      let(:levels) { 1 }

      it 'only flattens that many levels' do
        [
          1,
          2,
          3,
          [4, [5]],
          6,
        ].each do |value|
          expect(step).to receive(:call).with(inner_result, value).and_return(inner_result)
        end

        expect(subject).to eq(inner_result)
      end
    end
  end
end
