require "rails_helper"

RSpec.describe Cart, type: :model do
  it { should belong_to(:user).optional }
  it { should have_many(:cart_items).dependent(:destroy) }

  it { should define_enum_for(:status).with_values(
    active: 1, abandoned: 2, ordered: 3, cancelled: 0
  ) }
  it { should validate_presence_of(:status) }
end
