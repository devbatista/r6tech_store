require "rails_helper"

RSpec.describe Order, "e-mails de notificação", type: :model do
  include ActiveJob::TestHelper

  let!(:user) { User.create!(name: "Customer", email: "customer@example.com", password: "password") }

  before { Setting.instance.update!(notify_on_paid: true, notify_on_shipped: true, notify_on_delivered: false) }

  it "enqueues the confirmation e-mail when an order is created" do
    expect { user.orders.create!(status: :pending, total: 100) }
      .to have_enqueued_mail(OrderMailer, :confirmation)
  end

  it "enqueues the e-mail for a status change when the store enabled it" do
    order = user.orders.create!(status: :pending, total: 100)

    expect { order.update!(status: :paid) }.to have_enqueued_mail(OrderMailer, :paid).with(params: { order: order }, args: [])
    expect { order.update!(status: :shipped) }.to have_enqueued_mail(OrderMailer, :shipped)
  end

  it "does not enqueue e-mails the store disabled" do
    order = user.orders.create!(status: :shipped, total: 100)

    expect { order.update!(status: :delivered) }.not_to have_enqueued_mail(OrderMailer, :delivered)
  end

  it "does not enqueue e-mails for cancellations" do
    order = user.orders.create!(status: :pending, total: 100)

    expect { order.update!(status: :cancelled) }.not_to have_enqueued_mail(OrderMailer)
  end

  it "does not enqueue e-mails when other attributes change" do
    order = user.orders.create!(status: :pending, total: 100)

    expect { order.update!(total: 120) }.not_to have_enqueued_mail(OrderMailer)
  end
end
