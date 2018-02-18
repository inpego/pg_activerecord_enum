RSpec.describe PgEnum do
  it 'has a version number' do
    expect(PgEnum::VERSION).not_to be nil
  end

  let(:connection) { double }
  before { allow(ActiveRecord::Base).to receive(:connection).and_return(connection) }

  describe '.define' do
    it 'successfully sent CREATE TYPE statement' do
      expect(connection).to receive(:execute).with("CREATE TYPE foo AS ENUM ('bar', 'baz');")
      PgEnum.define :foo, %i[bar baz]
    end
  end

  describe '.drop' do
    it 'successfully sent DROP TYPE statement' do
      expect(connection).to receive(:execute).with('DROP TYPE foo;')
      PgEnum.drop :foo
    end
  end
end
