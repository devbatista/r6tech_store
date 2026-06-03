require "rails_helper"

RSpec.describe User, type: :model do
  subject { described_class.new(name: "Test User", email: "test@example.com", password: "password123") }

  it { should have_many(:carts) }
  it { should have_many(:orders) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:email) }
  it { should validate_uniqueness_of(:email).case_insensitive }
  it { should define_enum_for(:role).with_values(%i[customer admin]) }
end
