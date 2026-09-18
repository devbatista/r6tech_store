require "rails_helper"

RSpec.describe "Webhooks do Mercado Pago", type: :request do
  include ActiveJob::TestHelper

  let(:secret) { "whsec_test" }
  let(:request_id) { "req-123" }
  let(:timestamp) { "1704908010" }

  before { allow(Payments::Providers::MercadoPago::Client).to receive(:webhook_secret).and_return(secret) }

  def signature_for(data_id)
    manifest = "id:#{data_id};request-id:#{request_id};ts:#{timestamp};"
    "ts=#{timestamp},v1=#{OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)}"
  end

  def notify(data_id:, type: "payment", signature: signature_for(data_id))
    post "/webhooks/mercado_pago?data.id=#{data_id}&type=#{type}",
         params: { action: "payment.updated", type: type, data: { id: data_id } }.to_json,
         headers: { "Content-Type" => "application/json", "x-signature" => signature, "x-request-id" => request_id }
  end

  it "enqueues a sync for a signed payment notification" do
    expect { notify(data_id: "987") }.to have_enqueued_job(Payments::SyncJob).with("987")
    expect(response).to have_http_status(:ok)
  end

  it "lowercases alphanumeric ids before signing" do
    expect { notify(data_id: "ABC123", signature: signature_for("abc123")) }.to have_enqueued_job(Payments::SyncJob).with("ABC123")
    expect(response).to have_http_status(:ok)
  end

  it "rejects an invalid signature" do
    expect { notify(data_id: "987", signature: "ts=#{timestamp},v1=deadbeef") }.not_to have_enqueued_job
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects notifications when no secret is configured" do
    allow(Payments::Providers::MercadoPago::Client).to receive(:webhook_secret).and_return(nil)

    notify(data_id: "987")

    expect(response).to have_http_status(:unauthorized)
  end

  it "acknowledges other notification types without doing anything" do
    expect { notify(data_id: "555", type: "merchant_order") }.not_to have_enqueued_job
    expect(response).to have_http_status(:ok)
  end
end
