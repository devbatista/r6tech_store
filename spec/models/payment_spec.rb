require "rails_helper"

RSpec.describe Payment, type: :model do
  it { should belong_to(:order) }
  it { should validate_presence_of(:payment_method) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:amount) }
  it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }
end
