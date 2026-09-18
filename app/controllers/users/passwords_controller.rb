module Users
  class PasswordsController < Devise::PasswordsController
    include BaseDeviseController
  end
end
