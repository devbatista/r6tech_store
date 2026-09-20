require "rails_helper"

RSpec.describe Storage, type: :model do
  it { should have_many(:product_storages).dependent(:destroy) }
  it { should have_many(:products).through(:product_storages) }
  it { should have_many(:product_variants).dependent(:destroy) }

  it { should validate_presence_of(:value) }
  it { should validate_inclusion_of(:value).in_array(Storage::VALID_STORAGES) }

  it "accepts every catalog capacity" do
    Storage::VALID_STORAGES.each do |value|
      expect(Storage.new(value: value)).to be_valid, "expected #{value} to be valid"
    end
  end

  it "rejects capacities outside the catalog" do
    expect(Storage.new(value: "96GB")).not_to be_valid
  end
end
