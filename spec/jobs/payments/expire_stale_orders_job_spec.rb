require "rails_helper"

RSpec.describe Payments::ExpireStaleOrdersJob do
  let!(:user) { User.create!(name: "Customer", email: "customer@example.com", password: "password") }

  def create_order(status: :pending, payment_status: :awaiting_payment, created_at: 4.days.ago)
    user.orders.create!(status: status, total: 100, created_at: created_at).tap do |order|
      order.create_payment!(payment_method: :pix, amount: 100, status: payment_status)
    end
  end

  it "cancels old pending orders whose payment never completed" do
    stale = create_order
    failed = create_order(payment_status: :failed)

    described_class.perform_now

    expect(stale.reload).to be_cancelled
    expect(stale.payment).to be_cancelled
    expect(failed.reload).to be_cancelled
  end

  it "leaves recent, processing or paid orders alone" do
    recent = create_order(created_at: 1.day.ago)
    processing = create_order(payment_status: :processing)
    paid = create_order(status: :paid, payment_status: :paid)

    described_class.perform_now

    expect(recent.reload).to be_pending
    expect(processing.reload).to be_pending
    expect(paid.reload).to be_paid
  end
end
