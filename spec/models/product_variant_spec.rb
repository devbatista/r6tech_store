require "rails_helper"

RSpec.describe ProductVariant, type: :model do
  it { should belong_to(:product) }
  it { should belong_to(:memory) }
  it { should belong_to(:storage) }
  it { should validate_presence_of(:price) }
  it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
end
