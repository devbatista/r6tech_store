puts "Creating users"

# create admin user
User.create!(
  name: "Rafael Batista",
  email: "rafael@devbatista.com",
  password: "senha123",
  password_confirmation: "senha123",
  phone: '+55 11 98681-9042',
  role: :admin
)

# create customer user (admin não precisa de endereço)
customer = User.create!(
  name: "Robertson Costa",
  email: "robertson@virtualshop.com",
  password: "senha123",
  password_confirmation: "senha123",
  phone: '+55 11 99130-8008',
  role: :customer
)

customer.addresses.create!(
  label: "Casa",
  recipient: "Robertson Costa",
  zip_code: "01310-100",
  street: "Avenida Paulista",
  number: "1578",
  complement: "Apto 92",
  neighborhood: "Bela Vista",
  city: "São Paulo",
  state: "SP",
  country: "Brasil",
  default: true
)

customer.addresses.create!(
  label: "Trabalho",
  recipient: "Robertson Costa",
  zip_code: "04543-011",
  street: "Avenida Brigadeiro Faria Lima",
  number: "3477",
  complement: "14º andar",
  neighborhood: "Itaim Bibi",
  city: "São Paulo",
  state: "SP",
  country: "Brasil",
  default: false
)

puts "Users created successfully"