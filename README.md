# R6Tech Store

E-commerce de eletrônicos (celulares e afins) construído com Ruby on Rails. Possui uma vitrine para o cliente (storefront) e um painel administrativo completo, com cotação de frete via Melhor Envio e geração de descrições/imagens de produto com IA.

> ⚠️ Projeto em desenvolvimento ativo, usado como plataforma de estudo. Novas funcionalidades são adicionadas ao longo do tempo. Sugestões e contribuições são bem-vindas.

## Stack

- Ruby 3.3.1 · Rails 8.1
- PostgreSQL (UUID como chave primária em todas as tabelas)
- Hotwire (Turbo + Stimulus) com importmap
- Sprockets + Sass para assets
- Devise para autenticação
- Active Storage para imagens de produto
- Sidekiq + sidekiq-scheduler (Redis) para jobs em background
- Kaminari para paginação
- RSpec, FactoryBot, Shoulda Matchers e Capybara para testes
- Docker Compose para desenvolvimento

## Funcionalidades

### Storefront (cliente)

- Home com banners, vitrine de produtos e chamada para avaliação de aparelhos usados via WhatsApp
- Catálogo e página de produto com seleção de variação (cor, memória RAM e armazenamento)
- Carrinho com atualização via Turbo Streams e drawer lateral; carrinho anônimo é mesclado ao carrinho do usuário no login
- Conta do cliente: dados pessoais, múltiplos endereços (com busca por CEP) e histórico de pedidos
- Checkout com cotação de frete em tempo real (Melhor Envio) e escolha de meio de pagamento (PIX, cartão de crédito ou boleto, conforme habilitado nas configurações)
- Pedidos com endereço de entrega congelado no momento da compra e cancelamento pelo cliente

### Painel administrativo (`/admin`)

- Dashboard
- Produtos: CRUD, imagens, dimensões/peso para frete e variações (cor × memória × armazenamento, cada uma com seu preço)
- Categorias hierárquicas (categoria pai/subcategorias)
- Pedidos: listagem, detalhe e atualização de status respeitando as transições permitidas
- Clientes
- Configurações da loja: dados de contato e redes sociais, frete, notificações, meios de pagamento, aparência (dark mode), cores, armazenamentos e administradores

### Sugestões com IA

O admin pode gerar descrição e imagem de um produto com IA (OpenAI Responses API) e aprová-las antes de publicar. Um job agendado (`ProductAiSuggestionSweepJob`, a cada 5 minutos) enfileira sugestões para produtos que ainda não têm conteúdo gerado. A lógica está em `app/services/ai/` e o agendamento em `config/sidekiq.yml`.

## Modelos principais

| Modelo | Descrição |
| --- | --- |
| `User` | Devise; roles `customer` (padrão) e `admin`; possui endereços, carrinhos e pedidos |
| `Address` | Endereços do cliente, com marcação de endereço padrão |
| `Category` | Auto-referenciada (pai/filhas); nome único por pai |
| `Product` | Pertence a uma categoria; imagens via Active Storage; peso e dimensões para frete; status das sugestões de IA |
| `Color`, `Memory`, `Storage` | Atributos de variação |
| `ProductColor`, `ProductStorage`, `ProductVariant` | Ligações produto ↔ atributos; `ProductVariant` guarda o preço da combinação cor + memória + armazenamento |
| `Cart` / `CartItem` | Status `active`, `abandoned`, `ordered`, `cancelled`; itens guardam a variação escolhida |
| `Order` / `OrderItem` | Status `pending` → `paid` → `shipped` → `delivered` (ou `cancelled`); itens guardam preço e variação no momento da compra; dados de frete e endereço são copiados para o pedido |
| `Payment` | Um por pedido; método `pix`, `credit_card` ou `boleto`; status `awaiting_payment`, `processing`, `paid`, `failed`, `cancelled`, `refunded` |
| `Setting` | Registro único com as configurações da loja |

## Serviços

- `Shipping::Quote` / `Shipping::CheckoutQuotes` — cotação de frete a partir do carrinho, usando o provider `Shipping::Providers::MelhorEnvio`
- `Ai::ProductSuggestionRunner`, `Ai::ProductDescriptionGenerator`, `Ai::ProductImageGenerator` — geração de conteúdo com o provider `Ai::Providers::OpenAi`
- `CartMerger` — mescla o carrinho de visitante com o do usuário autenticado

## Configuração

Copie `.env.example` e preencha as variáveis. As principais:

```sh
# Melhor Envio (sandbox)
MELHOR_ENVIO_BASE_URL=https://sandbox.melhorenvio.com.br
MELHOR_ENVIO_TOKEN=seu-token
MELHOR_ENVIO_ORIGIN_POSTAL_CODE=01001000
MELHOR_ENVIO_USER_AGENT=r6tech_store (seu-email@example.com)

# OpenAI (sugestões de IA)
OPENAI_API_KEY=sua-chave
OPENAI_TEXT_MODEL=gpt-4.1-mini
OPENAI_IMAGE_RESPONSE_MODEL=gpt-4.1-mini

# Sidekiq
REDIS_URL=redis://localhost:6379/0
SIDEKIQ_CONCURRENCY=5
```

Os tokens do Melhor Envio e da OpenAI também podem ser guardados nas credentials do Rails, em `melhor_envio.token` e `openai.api_key`. Para usar o Melhor Envio em produção, troque `MELHOR_ENVIO_BASE_URL` por `https://melhorenvio.com.br` e use um token de produção.

Para que a cotação de frete funcione, cada produto precisa ter peso (kg) e largura, altura e comprimento (cm) cadastrados.

## Rodando localmente

```sh
bundle install
rails db:setup
rails server
bundle exec sidekiq -C config/sidekiq.yml   # em outro terminal, requer Redis
```

Acesse em [http://localhost:3000](http://localhost:3000).

## Rodando com Docker

Adicione o domínio local ao seu hosts:

```sh
sudo sh -c 'echo "127.0.0.1 r6tech.store-local" >> /etc/hosts'
```

Suba a aplicação (web, Sidekiq, PostgreSQL e Redis):

```sh
docker compose up --build
```

A aplicação fica disponível em [http://r6tech.store-local](http://r6tech.store-local). O container roda `rails db:prepare` automaticamente antes de iniciar o servidor.

Portas e credenciais podem ser ajustadas por variáveis de ambiente:

```sh
WEB_PORT=80 POSTGRES_PORT=5454 docker compose up --build
```

Carregar dados de exemplo e rodar os testes dentro do container:

```sh
docker compose exec web rails db:seed
docker compose exec web bundle exec rspec
```

## Seeds

Os seeds ficam em `db/seeds/` e rodam em ordem:

- `0-prepare.rb` — limpa o banco
- `1-users.rb` — admin e cliente
- `2-categories.rb` — categorias e subcategorias
- `3-storages.rb`, `4-colors.rb`, `5-memories.rb` — atributos de variação
- `5-products.rb` — produtos com variações
- `7-orders.rb` — pedidos de exemplo

```sh
rails db:seed
```

Usuários criados pelos seeds:

- Admin: `rafael@devbatista.com` / `senha123`
- Cliente: `robertson@virtualshop.com` / `senha123`

## Testes

```sh
bundle exec rspec
```
