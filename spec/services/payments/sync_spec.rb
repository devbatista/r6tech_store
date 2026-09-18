require "rails_helper"

RSpec.describe Payments::Sync do
  let!(:user) { User.create!(name: "Customer", email: "customer@example.com", password: "password") }
  let!(:order) { user.orders.create!(status: :pending, total: 100) }
  let!(:payment) { order.create_payment!(payment_method: :pix, amount: 100, status: :awaiting_payment) }
  let(:client) { Payments::Providers::MercadoPago::Client.new(access_token: "TEST-token") }

  def stub_payment(id: 987, status: "approved", status_detail: "accredited", external_reference: order.id, metadata: {})
    stub_request(:get, "https://api.mercadopago.com/v1/payments/#{id}").to_return(
      status: 200,
      body: {
        id: id, status: status, status_detail: status_detail, external_reference: external_reference,
        payment_type_id: "bank_transfer", payment_method_id: "pix", metadata: metadata
      }.to_json
    )
  end

  it "marks payment and order as paid for an approved payment" do
    stub_payment

    result = described_class.call(provider_payment_id: 987, client: client)

    expect(result).to eq(payment)
    expect(payment.reload).to be_paid
    expect(payment.external_reference).to eq("987")
    expect(payment.provider).to eq("mercado_pago")
    expect(payment.metadata).to include("provider_status" => "approved", "provider_status_detail" => "accredited", "payment_type" => "bank_transfer")
    expect(order.reload).to be_paid
  end

  it "is idempotent" do
    stub_payment

    2.times { described_class.call(provider_payment_id: 987, client: client) }

    expect(order.reload).to be_paid
  end

  it "keeps the order pending while the payment is in process" do
    stub_payment(status: "in_process", status_detail: "pending_review_manual")

    described_class.call(provider_payment_id: 987, client: client)

    expect(payment.reload).to be_processing
    expect(order.reload).to be_pending
  end

  it "keeps the order pending after a rejected attempt so the customer can retry" do
    stub_payment(status: "rejected", status_detail: "cc_rejected_insufficient_amount")

    described_class.call(provider_payment_id: 987, client: client)

    expect(payment.reload).to be_failed
    expect(payment).to be_payable
    expect(order.reload).to be_pending
  end

  it "cancels the order when the payment is cancelled" do
    stub_payment(status: "cancelled", status_detail: "expired")

    described_class.call(provider_payment_id: 987, client: client)

    expect(payment.reload).to be_cancelled
    expect(order.reload).to be_cancelled
  end

  it "records a refund and cancels a paid order" do
    order.update!(status: :paid)
    stub_payment(status: "refunded", status_detail: "refunded")

    described_class.call(provider_payment_id: 987, client: client)

    expect(payment.reload).to be_refunded
    expect(order.reload).to be_cancelled
  end

  it "does not move an order that cannot transition" do
    order.update!(status: :shipped)
    stub_payment(status: "charged_back", status_detail: "reimbursed")

    described_class.call(provider_payment_id: 987, client: client)

    expect(payment.reload).to be_refunded
    expect(order.reload).to be_shipped
  end

  it "finds the payment through the metadata when present" do
    other = user.orders.create!(status: :pending, total: 50).create_payment!(payment_method: :pix, amount: 50, status: :awaiting_payment)
    stub_payment(external_reference: "unknown", metadata: { payment_id: other.id })

    expect(described_class.call(provider_payment_id: 987, client: client)).to eq(other)
  end

  it "ignores payments that do not belong to the store" do
    stub_payment(external_reference: SecureRandom.uuid)

    expect(described_class.call(provider_payment_id: 987, client: client)).to be_nil
    expect(payment.reload).to be_awaiting_payment
  end
end
