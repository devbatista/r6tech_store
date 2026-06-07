require "rails_helper"

RSpec.describe Memory, type: :model do
  subject(:memory) { described_class.new(value: "16GB") }

  it { should validate_presence_of(:value) }
  it { should validate_uniqueness_of(:value) }
  it { should validate_inclusion_of(:value).in_array(Memory::VALID_MEMORIES) }
end
