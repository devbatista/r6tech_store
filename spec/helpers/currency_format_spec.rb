require "rails_helper"

RSpec.describe "currency formatting", type: :helper do
  it "formats values as Brazilian Real" do
    expect(helper.number_to_currency(1234.56)).to eq("R$ 1.234,56")
  end
end
