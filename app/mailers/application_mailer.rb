class ApplicationMailer < ActionMailer::Base
  # Remetente vem das configurações da loja (Admin > Configurações > Notificações).
  default from: -> { Setting.instance.sender_address }
  layout "mailer"
end
