RSpec.describe PgEnum do
  it 'has a version number' do
    expect(PgEnum::VERSION).not_to be nil
  end

  let(:connection) { double }
  before { allow(ActiveRecord::Base).to receive(:connection).and_return(connection) }

  describe '.define' do
    context 'when type does not exist' do
      it 'successfully sent CREATE TYPE statement' do
        allow(PgEnum).to receive(:values_for).with(:foo).and_return([])
        expect(connection).to receive(:execute).with("CREATE TYPE foo AS ENUM ('bar', 'baz');")
        PgEnum.define :foo, %i[bar baz]
      end
    end

    context 'when type already exists' do
      it 'raises ArgumentError for different values' do
        allow(PgEnum).to receive(:values_for).with(:foo).and_return(%w[fizz bar])
        expect { PgEnum.define :foo, %i[bar baz] }.to raise_error(
          ArgumentError, "Enum `foo` already defined with other values: 'fizz', 'bar' ('bar', 'baz' supplied)."
        )
      end

      it 'skips and writes to log for equal values' do
        allow(PgEnum).to receive(:values_for).with(:foo).and_return(%w[baz bar])
        expect(connection).not_to receive(:execute)
        expect(ActiveRecord::Base.logger).to receive(:info).with('Enum `foo` with same values already defined, skip.')
        PgEnum.define :foo, %i[bar baz]
      end
    end
  end

  describe '.drop' do
    it 'successfully sent DROP TYPE statement' do
      expect(connection).to receive(:execute).with('DROP TYPE IF EXISTS foo;')
      PgEnum.drop :foo
    end
  end
end
