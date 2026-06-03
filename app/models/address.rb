class Address < ApplicationRecord
  belongs_to :user

  validates :zip_code, :street, :city, :state, presence: true

  scope :defaults, -> { where(default: true) }

  before_save :unset_other_defaults, if: -> { default? }

  # Endereço em uma linha, ignorando partes em branco.
  def full_line(separator = ", ")
    [street, number, complement, neighborhood, city, state, zip_code, country]
      .map { |part| part.to_s.strip.presence }
      .compact
      .join(separator)
  end

  private

    # Garante que o usuário tenha apenas um endereço marcado como padrão.
    def unset_other_defaults
      user.addresses.where.not(id: id).update_all(default: false)
    end
end
