# Especificações do Sistema Para Agentes de IA

Este documento orienta agentes de IA que atuem neste projeto. Use-o como referência antes de propor mudanças, implementar funcionalidades ou gerar textos para o sistema.

## Regra Obrigatória de Idioma e Acentuação

- Todo texto em português do Brasil deve usar acentuação correta.
- Não escreva textos sem acento, como `nao`, `voce`, `catalogo`, `preco`, `opcao`, `duvida`, `informacao`, `sessao`, `validacao`.
- Use sempre as formas corretas: `não`, `você`, `catálogo`, `preço`, `opção`, `dúvida`, `informação`, `sessão`, `validação`.
- Isso vale para:
  - textos de interface;
  - documentos `.md`;
  - prompts de IA;
  - mensagens de erro;
  - traduções em locale;
  - textos comerciais;
  - respostas geradas por agentes.
- Chaves técnicas, nomes de classes, métodos, rotas, tabelas e colunas devem permanecer em inglês ou no padrão já usado no projeto.

## Visão Geral

O sistema é uma loja Rails para venda de produtos de tecnologia, com foco atual em produtos Apple e acessórios.

Principais áreas:

- Storefront público.
- Catálogo de produtos.
- Página de produto com opções e variantes.
- Carrinho.
- Pedidos.
- Área de conta do cliente.
- Admin para produtos, categorias, pedidos, clientes e configurações.
- Integração com OpenAI para sugestões de descrição e imagem de produto.

## Stack e Execução

- Rails 8.1.
- PostgreSQL com UUID via `pgcrypto`.
- Devise para autenticação.
- Sidekiq para jobs.
- Active Storage para imagens.
- Stimulus/Turbo no frontend.
- Docker Compose é o ambiente principal de execução.

Quando precisar rodar Rails neste projeto, prefira o container:

```bash
docker compose exec -T web bin/rails ...
```

Comandos úteis:

```bash
docker compose ps
docker compose exec -T web bin/rails runner 'puts Rails.env'
docker compose exec -T web bundle exec rspec
```

## Estrutura Principal

### Storefront

Arquivos relevantes:

- `app/views/layouts/storefront.html.erb`
- `app/views/storefront/_header.html.erb`
- `app/views/storefront/_footer.html.erb`
- `app/views/storefront/_cart_drawer.html.erb`
- `app/views/storefront/_product_card.html.erb`
- `app/views/home/index.html.erb`
- `app/views/products/index.html.erb`
- `app/views/products/show.html.erb`
- `app/assets/stylesheets/storefront/storefront.css`

Controllers:

- `HomeController`
- `ProductsController`
- `CartsController`
- `CartItemsController`
- `OrdersController`
- `AccountsController`
- `AddressesController`

### Admin

Arquivos relevantes:

- `app/controllers/admin/base_admin_controller.rb`
- `app/controllers/admin/products_controller.rb`
- `app/controllers/admin/categories_controller.rb`
- `app/controllers/admin/orders_controller.rb`
- `app/controllers/admin/clients_controller.rb`
- `app/controllers/admin/settings/*`
- `app/views/admin/**/*`

Rotas principais:

- `/admin`
- `/admin/products`
- `/admin/categories`
- `/admin/orders`
- `/admin/clients`
- `/admin/settings/store`

## Modelos de Domínio

### Usuários

Modelo: `User`

- Usa Devise.
- Roles:
  - `customer`
  - `admin`
- Clientes são usuários com role `customer`.

### Produtos

Modelo: `Product`

Campos importantes:

- `name`
- `description`
- `price`
- `category_id`
- `ai_description`
- `ai_description_status`
- `ai_image_status`
- `ai_error`

Associações:

- pertence a `Category`;
- possui imagens via Active Storage;
- possui imagens geradas por IA via Active Storage;
- possui `product_colors`;
- possui `product_storages`;
- possui `product_variants`;
- possui `cart_items`;
- possui `order_items`.

Regras úteis:

- `from_price` retorna o menor preço disponível entre variantes, armazenamentos ou preço base.
- `uses_variants?` indica produtos vendidos por combinação de cor, memória e armazenamento.
- `display_colors` escolhe cores de variantes ou cores simples.

### Categorias

Modelo: `Category`

- Suporta hierarquia por `parent_id`.
- `Category.roots` é usado no storefront e no menu.
- Categorias podem influenciar uso de variantes.

### Variações de Produto

Modelos:

- `Color`
- `Storage`
- `Memory`
- `ProductColor`
- `ProductStorage`
- `ProductVariant`

Uso:

- Produtos simples podem ter cores ou armazenamentos separados.
- Produtos mais complexos podem usar `ProductVariant` com combinação de cor, memória e armazenamento.
- `CartItem` e `OrderItem` preservam seleção de `color`, `memory` e `storage`.

### Carrinho

Modelos:

- `Cart`
- `CartItem`

Regras:

- Carrinho pode ser anônimo ou vinculado a usuário.
- `Cart#add_product` agrupa itens por produto e opções selecionadas.
- `Cart#total_value` soma os itens.
- `Cart#shipping_cost` considera `Setting.free_shipping_threshold` e `Setting.shipping_fee`.

### Pedidos

Modelos:

- `Order`
- `OrderItem`
- `Address`

Status:

- `pending`
- `paid`
- `shipped`
- `delivered`
- `cancelled`

Transições permitidas:

- `pending` -> `paid`, `cancelled`
- `paid` -> `shipped`, `cancelled`
- `shipped` -> `delivered`
- `delivered` -> nenhuma
- `cancelled` -> nenhuma

O pedido copia os dados do endereço no momento da criação para preservar o histórico.

### Configurações da Loja

Modelo: `Setting`

É singleton via `Setting.instance`.

Campos importantes:

- `store_name`
- `contact_email`
- `contact_phone`
- `whatsapp`
- `instagram_url`
- `facebook_url`
- `shipping_fee`
- `free_shipping_threshold`
- `default_order_status`
- flags de pagamento e notificações

O helper `storefront_whatsapp_url` usa `contact_phone`, remove caracteres não numéricos e monta o link `wa.me`.

## Integração de IA Existente

Namespace principal: `Ai`.

Arquivos:

- `app/services/ai/providers/open_ai.rb`
- `app/services/ai/providers/base.rb`
- `app/services/ai/product_suggestion_runner.rb`
- `app/services/ai/product_description_generator.rb`
- `app/services/ai/product_image_generator.rb`
- `app/jobs/product_ai_suggestion_job.rb`
- `app/jobs/product_ai_suggestion_sweep_job.rb`

Provider atual:

- Usa `https://api.openai.com/v1/responses`.
- Lê chave de `Rails.application.credentials.dig(:openai, :api_key)` ou `ENV["OPENAI_API_KEY"]`.
- Modelo de texto vem de `OPENAI_TEXT_MODEL`.
- Modelo para imagem vem de `OPENAI_IMAGE_RESPONSE_MODEL`.

Funcionalidades atuais:

- Geração de descrição comercial de produto.
- Geração de imagem de produto.
- Status de IA em `Product`:
  - `idle`
  - `pending`
  - `ready`
  - `approved`
  - `failed`

Ao criar novos agentes de IA, reaproveite o padrão desse namespace antes de criar outra integração paralela.

## Planejamento do Agente Especialista Apple

O plano detalhado está em:

```text
tmp/plans/apple-specialist-agent.md
```

Diretrizes resumidas:

- O agente deve ser consultor comercial da R6 Tech Store.
- Não deve se declarar suporte oficial da Apple.
- Não deve inventar preço, estoque, garantia, prazo ou disponibilidade.
- Deve consultar dados reais do catálogo por ferramentas internas.
- Deve encaminhar para WhatsApp quando a pergunta exigir atendimento humano.
- Todo texto em português deve ter acentuação correta.

## Convenções de UI e Texto

- Textos de storefront devem ser claros, curtos e comerciais.
- Textos administrativos devem ser objetivos e operacionais.
- Não misture português sem acento com português acentuado.
- Evite termos vagos quando houver dado real disponível.
- Evite promessas não representadas no banco ou nas configurações.
- Quando uma informação não existir, diga que ela não está cadastrada.

Exemplo correto:

```text
Não encontrei essa informação no cadastro da loja. Posso te direcionar para um vendedor no WhatsApp para confirmar com segurança.
```

Exemplo incorreto:

```text
Nao encontrei essa informacao no cadastro da loja.
```

## Regras Para Agentes ao Implementar

- Leia o código existente antes de propor arquitetura.
- Prefira padrões já usados no app.
- Para Rails no ambiente local, use Docker Compose.
- Não altere dados ou arquivos fora do escopo da tarefa.
- Não remova mudanças existentes feitas pelo usuário.
- Ao escrever Markdown ou prompts em português, revise acentuação.
- Ao criar funcionalidades de IA, registre limites, riscos e fallback humano.
- Ao mexer com dados comerciais, não invente regras de negócio.
- Ao mexer com pedidos, respeite transições de status.
- Ao mexer com carrinho, preserve opções selecionadas de produto.
- Ao mexer com produtos, considere variantes, cores, memórias e armazenamentos.

## Pontos de Atenção

- O app tem alguns textos legados sem acentuação em código ou docs antigos; novos textos devem ser corrigidos e acentuados.
- O botão de WhatsApp no storefront depende de telefone de contato cadastrado.
- O render direto por `rails runner` pode falhar se depender de Devise/Warden; para validar layout completo, prefira uma requisição HTTP real ao container web.
- Produtos Apple no seed e no catálogo podem ter nomes com grafia específica; preserve nomes de modelos e marcas.
- Não use a palavra "oficial" para atendimento Apple a menos que exista comprovação e regra de negócio cadastrada.

