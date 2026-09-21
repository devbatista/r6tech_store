# Checklist de Desenvolvimento

Pendências do projeto organizadas por prioridade, em duas fases: a **fase 1** (itens 1–7, levantada em 18/09/2026 e concluída em 19/09/2026) e a **fase 2** (itens 8–17, levantada em 21/09/2026 a partir do que ficou evidente durante a fase 1). Cada item traz as tarefas e, quando há mais de um caminho possível, as opções com uma recomendação. Marque a opção escolhida em **Decisão** antes de começar a implementação, para que o histórico da escolha fique registrado aqui.

Legenda de prioridade:

- 🔴 Bloqueia deploy ou a suíte de testes
- 🟠 Funcionalidade incompleta visível para o cliente ou para o admin
- 🟡 Dívida técnica e limpeza

---

## ✅ 1. Corrigir compilação de CSS (suíte de testes e deploy)

**Concluído em 18/09/2026.** Sprockets + `sassc-rails` foram substituídos por Propshaft + `dartsass-rails`. Suíte com 151 exemplos e 0 falhas; `assets:precompile` de produção passando.

**Problema:** `app/assets/stylesheets/storefront/storefront.css` usa `max()` e `min()` nativos do CSS. O `sassc-rails` (libsass) interpreta como funções Sass e falha. Em `development` o CSS não passa pelo compressor, mas em `test` e no `assets:precompile` de produção ele passa. Resultado: 30 specs falhando e deploy quebrado.

**Decisão — como resolver o compressor:**

- [x] **A. Migrar para `dartsass-rails`** (recomendado) — **escolhida**
  Substitui o `sassc-rails`, que está deprecado. O Dart Sass entende `min()`/`max()`/`clamp()` nativos. Exige mover os `.scss` para `app/assets/stylesheets` com um entrypoint e rodar o build via `bin/rails dartsass:build` / `dartsass:watch`. Mudança moderada, mas resolve a causa raiz e tira uma gem morta do projeto.
  Na prática exigiu trocar também Sprockets por Propshaft: o SCSS usava `font-url()`/`asset-url()`, que só existem no `sassc-rails`, e o Sprockets não reescreve `url()` em CSS puro — as fontes com digest quebrariam em produção. O Propshaft faz essa reescrita e é o padrão do Rails 8.
- [ ] **B. Desativar o compressor Sass**
  `config.assets.css_compressor = nil` em `production.rb` e `test.rb`. Correção de uma linha; o CSS fica sem minificação e o `sassc-rails` continua no projeto.
- [ ] **C. Contornar no CSS**
  Trocar `max(20px, calc(...))` por media queries ou `unquote()`. Resolve só este caso; o problema volta na próxima vez que alguém usar uma função nativa.

**Tarefas:**

- [x] Aplicar a decisão acima
  - `Gemfile`: `propshaft` + `dartsass-rails` no lugar de `sprockets-rails` + `sassc-rails`
  - `app/assets/config/manifest.js` removido (só existia para o Sprockets)
  - `font-url()`/`asset-url()` → `url()` em `icon/style.scss` e `scss/component/_sections.scss`
  - `icon/style` removido do `stylesheet_link_tag` do layout admin (já é importado por `application.scss`)
  - `config/initializers/dartsass.rb` com as opções de build; `app/assets/builds/` ignorado no git
  - `bin/dev` + `Procfile.dev`, serviço `css` no `docker-compose.yml`, `dartsass:build` no `bin/docker-dev-entrypoint`
  - `spec/rails_helper.rb` builda o CSS em `before(:suite)` (rspec não passa por `test:prepare`)
  - Arquivos de demo do icomoon removidos de `app/assets/stylesheets/icon/`; `selection.json` movido para `docs/icomoon-selection.json`
- [x] Revisar `storefront.css:46`: `min-width: 650px` removido no item 7
- [x] Rodar `bundle exec rspec` e confirmar 0 falhas
- [x] Rodar `RAILS_ENV=production bin/rails assets:precompile` localmente para confirmar que o build passa
- [ ] Adicionar `assets:precompile` ao pipeline de CI (ou ao `Dockerfile`) para que isso não volte a passar despercebido
- [ ] Migrar os partials SCSS de `@import` para `@use`/`@forward` (o Dart Sass 3.0 vai remover `@import`; o aviso está silenciado em `config/initializers/dartsass.rb`)
- [x] `app/assets/stylesheets/scss/app.scss` removido no item 7

---

## ✅ 2. Processar pagamentos de verdade

**Concluído em 18/09/2026.** Mercado Pago Checkout Pro (redirect) com webhook assinado, URL de retorno, nova tentativa pela página do pedido e expiração automática. Suíte com 204 exemplos e 0 falhas. Falta só a parte operacional (credenciais e cadastro do webhook), que depende do domínio.

**Problema:** `Payment` é criado com `awaiting_payment` e nada acontece depois. Não há gateway, webhook, nem uso de `provider`/`external_reference`. Os campos de cartão do checkout são só visuais. O pedido só vira `paid` quando o admin muda o status manualmente.

**Decisão — gateway de pagamento:**

- [x] **A. Mercado Pago** (recomendado para começar) — **escolhida**
  PIX, cartão e boleto no mesmo provedor, Checkout Pro (redirect) ou Checkout Transparente, SDK Ruby oficial, sandbox gratuito. Boa cobertura no Brasil e documentação em português.
- [ ] **B. Pagar.me / Stone**
  API completa, boa para cartão com antifraude. Exige contrato comercial antes do sandbox de produção.
- [ ] **C. Asaas**
  Forte em PIX e boleto, cobrança recorrente. Cartão mais limitado.
- [ ] **D. Stripe**
  Melhor DX, mas PIX e boleto têm suporte parcial no Brasil e exigem conta em BRL.

**Decisão — modo de integração:**

- [x] **A. Checkout hospedado / redirect** (recomendado) — **escolhida**
  O cliente é redirecionado para a página do gateway. Não há dados de cartão passando pela aplicação, o que elimina o escopo de PCI. Menos controle sobre o visual.
- [ ] **B. Checkout transparente**
  O form fica na loja e envia um token do gateway. Visual próprio, mas exige tokenização no frontend e mais cuidado com segurança.

**Tarefas:**

- [x] `Payments::Providers::MercadoPago::Client` (HTTP), `Preference` (payload do Checkout Pro) e `WebhookSignature` (validação do `x-signature`), no padrão de `Shipping::Providers::MelhorEnvio`
- [x] `Payments::Checkout` cria a preference (idempotente por `payment.id`) e guarda `provider`, `preference_id` e `init_point` no `Payment`
- [x] `Payments::Sync` consulta `/v1/payments/:id`, grava `external_reference` (id do pagamento no MP) e o status, e move o pedido (`pending → paid`, `cancelled`/`refunded → cancelled` quando a transição é permitida)
- [x] `POST /webhooks/mercado_pago` valida a assinatura, responde 200 e enfileira `Payments::SyncJob` (retry em erro do provedor)
- [x] `GET /orders/:id/payment/return` (back_url) sincroniza pelo `payment_id` da query, sem confiar no `status` da query
- [x] `POST /orders/:id/pay` reabre o checkout para pedidos `awaiting_payment`/`failed` (nova tentativa após recusa)
- [x] Expiração: `Payments::ExpireStaleOrdersJob` (hora em hora) cancela pedidos pendentes há mais de 3 dias sem pagamento
- [x] Campos de cartão removidos do checkout e do `payment_form_controller.js`; o método escolhido na loja restringe os tipos de pagamento exibidos pelo Mercado Pago
- [x] Admin > Pedido mostra provedor, id do pagamento no MP e status/detalhe originais
- [x] Credenciais em `credentials` (`mercado_pago.access_token`, `mercado_pago.webhook_secret`) ou `MERCADO_PAGO_*`; README, `.env.example` e compose atualizados
- [x] Specs: `spec/services/payments/*`, `spec/requests/webhooks/mercado_pago_spec.rb`, `spec/jobs/payments/*`, controllers e system (`webmock` adicionado ao grupo de teste)

**Pendências operacionais (fora do código):**

- [ ] Criar a aplicação no painel de desenvolvedor do Mercado Pago e obter as credenciais de teste (`TEST-...`) e de produção
- [ ] Testar o fluxo no sandbox com usuários de teste (comprador e vendedor) do Mercado Pago
- [ ] Cadastrar o webhook em `https://<APP_HOST>/webhooks/mercado_pago` (evento *Pagamentos*) e copiar a assinatura secreta para `mercado_pago.webhook_secret` — depende do domínio existir e servir HTTPS
- [ ] Em desenvolvimento, para receber webhooks, expor a máquina com um túnel (ngrok, Cloudflare Tunnel) e definir `APP_HOST` com esse host; sem isso o status chega só pela URL de retorno

**Decisões menores tomadas:**

- A loja continua pedindo o método (PIX, cartão, boleto) antes do redirect e usa `excluded_payment_types` para o Mercado Pago mostrar só aquele tipo. Se preferir deixar o cliente escolher lá, é só parar de enviar a exclusão em `Preference#excluded_payment_types`.
- Frete vai em `shipments.cost` (modo `not_specified`), não como item.
- Recusa de cartão não cancela o pedido: `Payment` vira `failed` e o botão "Pagar agora" permite tentar de novo pela mesma preference.
- `Order#sync_payment_status` não sobrescreve mais um pagamento `refunded` com `cancelled` ao cancelar o pedido.

---

## ✅ 3. Notificações por e-mail

**Concluído em 18/09/2026.** `OrderMailer` com confirmação, pagamento, envio e entrega; Amazon SES via SMTP em produção; `letter_opener_web` em desenvolvimento. Suíte com 172 exemplos e 0 falhas.

**Problema:** As flags `notify_on_paid`, `notify_on_shipped`, `notify_on_delivered` e `notification_sender` são salvas em `Setting`, mas não existe nenhum mailer além do `ApplicationMailer` vazio. SMTP não está configurado em produção, então o "Esqueci minha senha" do Devise ainda não entrega e-mail.

**Decisão — serviço de envio:**

- [ ] **A. Resend** (recomendado)
  API simples, 3 mil e-mails/mês grátis, entrega boa, integra via SMTP ou gem oficial.
- [x] **B. Amazon SES** — **escolhida**
  Mais barato em volume, mas configuração de domínio e saída do sandbox mais burocráticas.
- [ ] **C. Brevo (ex-Sendinblue)**
  Plano gratuito generoso, painel com métricas. Boa opção se também quiser marketing.
- [ ] **D. SMTP genérico (Gmail/Google Workspace)**
  Só para desenvolvimento ou volume muito baixo. Limites diários e risco de bloqueio.

**Tarefas:**

- [x] `production.rb`: `delivery_method = :smtp` apontando para `email-smtp.<região>.amazonaws.com:587` (STARTTLS); credenciais em `credentials` sob `aws.ses` ou em `SES_SMTP_USERNAME`/`SES_SMTP_PASSWORD`; `default_url_options` com `APP_HOST`
- [x] `Setting#sender_address` centraliza remetente e nome da loja; `ApplicationMailer` e o Devise usam o mesmo
- [x] `OrderMailer` com `confirmation`, `paid`, `shipped` e `delivered` (HTML + texto, pt-BR e en), respeitando `Setting#notify_on?`
- [x] Disparo por `after_create_commit` / `after_update_commit` em `Order`, via `deliver_later` (fila `default` do Sidekiq)
- [x] `letter_opener_web` em `/letter_opener` e preview em `/rails/mailers/order_mailer` (`spec/mailers/previews`)
- [x] Specs: `spec/mailers/order_mailer_spec.rb` e `spec/models/order_notifications_spec.rb`
- [x] `.env.example`, `docker-compose.yml` e README atualizados

**Pendências operacionais (fora do código):**

Bloqueadas até o domínio da loja existir (situação em 18/09/2026). Enquanto isso, o código está pronto e os e-mails só podem ser conferidos em desenvolvimento (`/letter_opener` e `/rails/mailers`).

- [ ] Registrar o domínio da loja
- [ ] Verificar o domínio do remetente no SES (registros DKIM/SPF no DNS)
- [ ] Solicitar saída do sandbox do SES (no sandbox só é possível enviar para endereços verificados)
- [ ] Gerar as credenciais SMTP no console do SES e gravar em `credentials` (`aws.ses.smtp_username`, `smtp_password`, `region`)
- [ ] Preencher o remetente em Admin > Configurações > Notificações com um e-mail do domínio verificado
- [ ] Definir `APP_HOST` em produção com o domínio público da loja

**Decisões menores tomadas:**

- Cancelamento não gera e-mail: não existe flag para isso nas configurações. Se quiser, é adicionar `notify_on_cancelled` em `Setting` e uma ação em `OrderMailer`.
- `raise_delivery_errors = true` em produção, para que uma falha de entrega faça o Sidekiq fazer retry em vez de sumir silenciosamente.

---

## ✅ 4. Unificar autenticação

**Concluído em 18/09/2026.** Sistema custom removido; login, cadastro e recuperação de senha passam pelo Devise com controllers em `app/controllers/users/`. Suíte com 162 exemplos e 0 falhas.

**Problema:** O storefront usa um `SessionsController` próprio com `session[:user_id]`, enquanto o modal de login linka para `new_user_registration_path` e `new_user_password_path` do Devise. Quem se cadastra pelo Devise fica autenticado no Warden, mas `BaseController#current_user` não enxerga — a pessoa cria a conta e continua deslogada. As telas do Devise usam o layout antigo (`application.html.erb`, Bootstrap), fora do visual da loja.

**Decisão — qual sistema manter:**

- [x] **A. Manter Devise e remover o `SessionsController` custom** (recomendado) — **escolhida**
  Devise já está no Gemfile e no modelo. Ganha recuperação de senha, `remember_me`, lockable e confirmação de e-mail de graça. É preciso customizar o `SessionsController` do Devise para preservar o merge de carrinho e o redirect de admin.
- [ ] **B. Remover Devise e manter o custom**
  Menos dependências, mas é preciso implementar do zero cadastro, recuperação de senha, remember-me e todas as proteções que o Devise já oferece.

**Tarefas:**

- [x] `Users::SessionsController`, `Users::RegistrationsController` e `Users::PasswordsController` (concern `Users::BaseDeviseController` com layout `storefront`, carrinho e merge via `CartMerger`)
- [x] `BaseController` usa o `current_user` do Devise; `session[:user_id]` e `session[:return_to]` substituídos por `store_location_for`
- [x] Views do Devise em `app/views/users/` no visual da loja (cadastro, esqueci a senha, nova senha); login continua no modal da home
- [x] Modal posta em `user_session_path` com campos `user[email]`/`user[password]`
- [x] Rotas `login`/`logout` manuais removidas; Devise responde em `/users/login` e `/users/logout`
- [x] Layout `application.html.erb` antigo removido; `UsersController` (sem rotas) removido
- [x] Coluna `users.password_digest` removida via migration
- [x] `bypass_sign_in` após troca de senha (conta do cliente e conta do admin), porque o Devise invalida a sessão quando o salt muda
- [x] `config.mailer_sender` do Devise lê `Setting#notification_sender` (com fallback), no lugar do placeholder
- [x] Specs: sessions (merge de carrinho, `return_to`, admin → painel, credenciais inválidas, logout) e registrations (cadastro → logado + merge, role não editável, erros)
- [ ] Decidir se `confirmable` será ativado (depende do item 3 estar pronto)
- [x] Sobras do Minitest removidas no item 7

**Comportamento que mudou:**

- Um usuário removido do banco enquanto logado agora vira visitante anônimo (padrão do Devise), em vez de receber o aviso "sessão expirada".
- `GET /users/edit` (edição de conta do Devise) redireciona para a página da conta, que já cuida de perfil e senha.

---

## ⛔ 5. Controle de estoque

**Não será feito — decisão de 18/09/2026.** A loja opera sem controle de estoque no sistema; disponibilidade é gerida fora dele. As opções abaixo ficam registradas caso a decisão mude.

**Problema:** Não existe coluna de estoque em `products` nem em `product_variants`. Qualquer quantidade pode ser vendida.

**Decisão — granularidade:**

- [ ] **A. Estoque por variante (`product_variants.stock`)** (recomendado)
  É onde o preço já vive. Cada combinação cor × memória × armazenamento tem sua quantidade. Produtos sem variação usam um registro de variante "padrão" ou uma coluna em `products` como fallback.
- [ ] **B. Estoque por produto (`products.stock`)**
  Mais simples, mas não reflete a realidade de uma loja de celulares, onde o iPhone preto de 256 GB pode acabar enquanto o branco ainda tem.

**Decisão — quando reservar:**

- [ ] **A. Baixar ao confirmar pagamento** (recomendado)
  Evita estoque preso por pedidos que nunca serão pagos. Aceita o risco de dois clientes pagarem o último item quase ao mesmo tempo, que é tratado com lock na baixa.
- [ ] **B. Reservar ao criar o pedido, liberar em cancelamento/expiração**
  Mais preciso, mas depende de o item 2 ter expiração de pagamento funcionando.

**Tarefas:**

- [ ] Migration adicionando `stock` (integer, default 0, not null) conforme a decisão
- [ ] Campo de estoque no form de produto/variante do admin
- [ ] Validar quantidade disponível em `CartItemsController#create/update` e no `PaymentsController#create`
- [ ] Baixa de estoque com `with_lock` no momento decidido acima; devolução em cancelamento
- [ ] Exibir "Esgotado" na página do produto e desabilitar a opção no `product_options_controller.js`
- [ ] Coluna de estoque e filtro "abaixo de X" na listagem de produtos do admin
- [ ] Specs: não permitir adicionar acima do estoque; baixa e devolução; concorrência básica

---

## ✅ 6. Configurações salvas mas ignoradas

**Concluído em 19/09/2026.** `tax_rate` e `default_order_status` removidos do formulário, do model, das traduções e do banco (migration `RemoveUnusedFieldsFromSettings`). Suíte com 204 exemplos e 0 falhas.

**Problema:** `tax_rate` e `default_order_status` são editáveis em `/admin/settings/shipping`, gravados em `Setting` e nunca lidos.

**Decisão — o que fazer com cada campo:**

- `tax_rate`
  - [x] **A. Remover campo e coluna** (recomendado) — **escolhida**
    No Brasil o imposto já está embutido no preço; uma taxa separada confunde o cliente.
  - [ ] **B. Aplicar no total do pedido**
    Somar `subtotal * tax_rate` em `Order.create_from_cart!` e mostrar a linha no carrinho e no pedido.
- `default_order_status`
  - [x] **A. Remover campo e coluna** (recomendado) — **escolhida**
    O status inicial de um pedido é sempre `pending`; deixar configurável permite quebrar as transições de `STATUS_TRANSITIONS`.
  - [ ] **B. Usar em `Order.create_from_cart!`**
    Só faz sentido se houver um caso real, como loja que aceita pedido sem pagamento online.

**Tarefas:**

- [x] Aplicar as decisões (migration de remoção ou uso real)
- [x] Atualizar `Admin::Settings::ShippingController` e a view correspondente
- [x] `Setting::ORDER_STATUSES` e as validações dos dois campos removidos; `spec/agents/system_specifications.md` atualizado

---

## ✅ 7. Limpeza e dívida técnica

**Concluído em 19/09/2026.** Suíte com 210 exemplos, 0 falhas e 0 pendentes. `docs/layouts/store/` foi mantido por decisão do time.

- [x] **`products.price` obrigatório mesmo com variações** — verificado: não é bug. `Admin::ProductsController#assign_base_price` já deriva o preço base da variação mais barata antes de salvar, então a validação nunca falha pelo formulário. Mantida como está.
- [x] **`hello_controller.js` removido** (o `index.js` carrega controllers por convenção, sem lista manual)
- [x] **`docs/layouts/store/`** — **mantido** (decisão de 19/09/2026): referência do tema original para páginas ainda não portadas.
- [x] **Seeds renumerados**: `5-products.rb` → `6-products.rb`, `db/seeds.rb` atualizado e seeds validados
- [x] **`spec/models/storage_spec.rb`** preenchido (associações, validações e catálogo de capacidades)
- [x] **Acentuação em `config/locales/pt-BR.yml`** — 69 linhas corrigidas (`endereço`, `opção`, `não`, `você`, `Métodos de pagamento`, mensagens de erro do Active Record etc.); `devise.pt-BR.yml` reescrito com acentos e "e-mail"
- [x] **Assets do admin** — Morris, Raphael e jVectorMap ficam (o dashboard usa o donut e o mapa). Removidos os `line-chart-{5,6,8,11,12,13,22}.js` órfãos e seus `javascript_include_tag`; os 20 scripts restantes do dashboard resolvem com 200.
- [x] Sobras do item 1: `scss/app.scss` (não era importado) removido; `min-width: 650px` do `.hero__content` removido (contradizia `width: min(650px, …)` e causava overflow entre 690 e 760 px)
- [x] Sobras do item 4: `spec/test_helper.rb`, `spec/application_system_test_case.rb`, `spec/channels/` e `spec/fixtures/*.yml` (Minitest) removidos; `spec/fixtures/files/` mantido

**Ainda em aberto:** ver a fase 2 abaixo (itens 9, 13, 14 e 17).

---

# Fase 2 — pendências levantadas em 21/09/2026

Itens que só ficaram evidentes durante a execução da fase 1. Mesma convenção: opções com recomendação onde há escolha, e a decisão registrada na tabela do final.

Legenda de prioridade:

- 🔴 Risco de perda de dados ou bloqueio de deploy
- 🟠 Funcionalidade incompleta visível para o cliente ou para o admin
- 🟡 Melhoria e dívida técnica

---

## ✅ 8. Uploads em produção (Active Storage)

**Concluído em 21/09/2026.** Produção usa o serviço `amazon` (S3, bucket privado com URLs assinadas); desenvolvimento e teste continuam em disco. Falta só criar o bucket e as credenciais na AWS.

**Problema:** `config/environments/production.rb` usa `active_storage.service = :local`. O container Docker de produção é efêmero, então imagens de produto, logo da loja e imagens geradas por IA somem a cada deploy ou restart.

**Decisão — onde guardar os arquivos:**

- [x] **A. Amazon S3** (recomendado) — **escolhida**
  A conta AWS já vai existir por causa do SES. Bucket privado + URLs assinadas pelo Active Storage; gem `aws-sdk-s3`.
- [ ] **B. Cloudflare R2**
  Compatível com S3 (mesma gem), sem custo de saída de dados. Bom se o tráfego de imagens for alto.
- [ ] **C. Volume persistente no host**
  Só faz sentido se o deploy for em servidor próprio com Kamal/Docker e um volume montado. Não escala para mais de um container.

**Tarefas:**

- [x] `aws-sdk-s3` e o serviço `amazon` em `config/storage.yml`: credenciais em `credentials` (`aws.s3.*`) ou `AWS_*`, com fallback para IAM role; `cache_control` de 1 ano nos objetos
- [x] `config.active_storage.service = :amazon` em produção
- [x] CORS documentado no README (o formulário de produto usa `direct_upload: true`)
- [x] Variantes: `image_processing`/libvips já estão no Dockerfile de produção; o `S3Service` baixa o original e sobe a variante, nada muda no código
- [x] `bin/rails storage:migrate FROM=local TO=amazon` para migrar blobs existentes
- [x] Verificado com boot em `RAILS_ENV=production`: serviço, bucket, região e credenciais resolvidos das variáveis

**Pendências operacionais (fora do código):**

- [ ] Criar o bucket (mesma região do SES, Block Public Access ligado) e o usuário IAM com permissão restrita ao bucket
- [ ] Aplicar o CORS do README com o domínio real em `AllowedOrigins`
- [ ] Gravar as credenciais em `credentials` (`aws.s3.*`) ou nas variáveis de ambiente da plataforma de deploy (item 9)

**Decisões menores tomadas:**

- Bucket privado com URLs assinadas (padrão do Rails) em vez de `public: true`: não exige liberar ACLs no bucket nem desligar o Block Public Access. Se no futuro for preciso CDN ou URLs permanentes para SEO de imagens (item 16), a troca é `public: true` no serviço + bucket com ACLs habilitadas ou CloudFront na frente.

---

## 🔴 9. Deploy e infraestrutura

**Problema:** existe `Dockerfile` de produção, mas nenhuma definição de onde e como a aplicação roda. Sem isso não há como fechar `RAILS_MASTER_KEY`, banco, Redis, Sidekiq e storage.

**Decisão — plataforma:**

- [ ] **A. Kamal em VPS** (recomendado para custo)
  Padrão do Rails 8; `kamal init` gera `config/deploy.yml`. Um servidor (Hetzner, DigitalOcean) roda web + Sidekiq + Postgres + Redis via Docker. Mais barato, exige cuidar de backup e atualizações.
- [ ] **B. PaaS (Render, Fly.io, Railway)**
  Postgres e Redis gerenciados, deploy por git push, menos operação. Custo mensal maior.

**Tarefas:**

- [ ] Configurar a plataforma escolhida com os serviços web, Sidekiq, Postgres e Redis
- [ ] Definir `RAILS_MASTER_KEY`, `APP_HOST`, `DATABASE_URL`, `REDIS_URL` e as credenciais dos itens 2, 3 e 8
- [ ] HTTPS (obrigatório para o webhook do Mercado Pago e para `force_ssl`)
- [ ] Backup automático do Postgres
- [ ] **CI**: workflow no GitHub Actions rodando `bundle exec rspec` e `RAILS_ENV=production bin/rails assets:precompile` a cada push (evita repetir o cenário do item 1)

---

## 🟠 10. Monitoramento e proteção

**Problema:** nenhuma ferramenta de erro (Sentry, Honeybadger) e nenhum rate limiting. Falhas em webhook, Sidekiq e e-mail vão só para o log; login e cadastro aceitam tentativas ilimitadas.

**Decisão — rastreamento de erros:**

- [ ] **A. Sentry** (recomendado)
  Plano gratuito suficiente para começar; captura Rails, Sidekiq e JS.
- [ ] **B. Honeybadger**
  Mais simples, foco em Ruby. Plano gratuito menor.

**Tarefas:**

- [ ] Instalar a gem escolhida com o DSN em `credentials`
- [ ] `rack-attack` com limites em `POST /users/login`, `POST /users`, `POST /users/password` e `POST /webhooks/mercado_pago`
- [ ] Alertas de fila do Sidekiq (jobs mortos) — o painel `sidekiq/web` pode ser montado em `/admin/sidekiq` só para admins
- [ ] Health check `/up` já existe; apontar o monitor da plataforma para ele

---

## 🟠 11. Páginas legais

**Problema:** não há termos de uso, política de privacidade nem política de trocas e devoluções. Para e-commerce no Brasil são exigidas pelo CDC (direito de arrependimento em 7 dias) e pela LGPD.

**Tarefas:**

- [ ] Páginas estáticas (ou editáveis no admin) para termos, privacidade e trocas/devoluções
- [ ] Links no rodapé da loja e aceite no cadastro/checkout
- [ ] Dados da empresa (CNPJ, endereço, contato) no rodapé — exigência do Decreto 7.962/2013
- [ ] Textos revisados por alguém com conhecimento jurídico antes de publicar

---

## 🟠 12. Dashboard e busca do admin

**Problema:** o dashboard mostra números, produtos ("Neptune Longsleeve") e o mapa dos EUA vindos do template do tema. O campo de busca do header do admin é um formulário estático que não faz nada.

**Tarefas:**

- [ ] Substituir os cards por métricas reais: pedidos e receita (hoje, 7 dias, 30 dias), ticket médio, pedidos por status, produtos mais vendidos, clientes novos
- [ ] Trocar os gráficos ApexCharts para consumir esses dados (`line-chart-1..4` e `7`) ou remover os que não fizerem sentido
- [ ] Remover o mapa dos EUA (jVectorMap, Raphael e Morris podem sair junto se nada mais os usar) ou trocar por dados por estado do Brasil
- [ ] Busca do header: procurar produtos, pedidos (por id curto) e clientes (por nome/e-mail)

---

## 🟠 13. Frete: etiqueta e rastreio

**Problema:** o Melhor Envio é usado só para cotar. Comprar a etiqueta, imprimir e obter o código de rastreio é manual e fora do sistema; o status `shipped` é marcado à mão e o e-mail de envio não leva rastreio.

**Decisão — escopo:**

- [ ] **A. Só rastreio** (recomendado para começar)
  Campo `tracking_code` no pedido, preenchido pelo admin ao marcar como enviado; e-mail de envio e página do pedido mostram o código com link para os Correios/transportadora.
- [ ] **B. Compra de etiqueta pelo sistema**
  Integrar o carrinho de fretes do Melhor Envio (`/api/v2/me/cart`, checkout, geração e impressão da etiqueta). Mais trabalho; depende de saldo na conta do Melhor Envio.

**Tarefas (opção A):**

- [ ] Migration `orders.tracking_code` e `orders.tracking_url`
- [ ] Campo no `update_status` do admin quando o novo status for `shipped`
- [ ] Exibir na página do pedido, na conta do cliente e em `OrderMailer#shipped`

---

## 🟠 14. Cancelamento e estorno

**Problema:** o cliente pode cancelar um pedido `pending` e o admin pode cancelar um `paid`, mas nada acontece no Mercado Pago: um pagamento aprovado continua aprovado lá e o dinheiro não volta.

**Tarefas:**

- [ ] `Payments::Refund` chamando `POST /v1/payments/:id/refunds` quando um pedido `paid` for cancelado pelo admin
- [ ] Definir se o cliente pode cancelar um pedido já pago (direito de arrependimento em 7 dias sugere que sim, com estorno)
- [ ] `OrderMailer#cancelled` (hoje cancelamento não gera e-mail) — exige a flag `notify_on_cancelled` em `Setting`
- [ ] Specs com `webmock` no padrão de `spec/services/payments`

---

## 🟡 15. Confirmação de e-mail no cadastro

**Problema:** qualquer e-mail é aceito no cadastro sem verificação. Depende do item 3 estar operacional (SES fora do sandbox).

**Tarefas:**

- [ ] Ativar `:confirmable` no `User` com a migration do Devise (`confirmation_token`, `confirmed_at`, `confirmation_sent_at`, `unconfirmed_email`)
- [ ] Decidir `allow_unconfirmed_access_for` (ex.: 2 dias) para não travar a compra de quem acabou de se cadastrar
- [ ] View `users/confirmations/new` no visual da loja e `Users::ConfirmationsController` com o `BaseDeviseController`
- [ ] Marcar como confirmados os usuários existentes na migration

---

## 🟡 16. Cadastro de produtos: SEO e catálogo

**Problema:** URLs usam UUID (`/products/5b8020de-…`), não há `sitemap.xml`, meta description nem dados estruturados. Para uma loja que depende de busca orgânica isso pesa.

**Tarefas:**

- [ ] Slug em produtos e categorias (`friendly_id` ou coluna `slug` própria) mantendo os UUIDs como redirect
- [ ] `sitemap.xml` (gem `sitemap_generator`) gerado por job diário
- [ ] Meta tags por página (título, descrição, Open Graph) e JSON-LD `Product`/`Offer` na página do produto
- [ ] `robots.txt` liberando a loja e bloqueando `/admin`, `/cart`, `/account`

---

## 🟡 17. Dívida técnica remanescente

- [ ] Migrar os partials SCSS de `@import` para `@use`/`@forward` antes do Dart Sass 3.0 (aviso silenciado em `config/initializers/dartsass.rb`)
- [ ] `Order#status` usa strings soltas em `STATUS_TRANSITIONS`; considerar uma state machine simples se as regras crescerem (estorno, devolução)
- [ ] Locale `en.yml` está desatualizado em relação ao `pt-BR.yml` em algumas seções do admin; decidir se o inglês continua sendo suportado ou remover o seletor de idioma
- [ ] Assets do admin ainda carregam jQuery e Bootstrap 5 completos; avaliar redução quando o dashboard for refeito (item 12)

---

## Ordem sugerida — fase 2

1. **Item 8 (storage)** — pequeno e evita perda de dados no primeiro deploy.
2. **Item 9 (deploy + CI)** — destrava os passos operacionais dos itens 2 e 3 e a verificação do domínio.
3. **Item 10 (monitoramento)** — antes de ter clientes reais.
4. **Item 11 (páginas legais)** — obrigatório antes de vender.
5. **Itens 13 e 14** — completam o ciclo do pedido (envio e estorno).
6. **Item 12** — dashboard útil para o dia a dia do admin.
7. **Itens 15, 16 e 17** — quando houver fôlego.

---

## Ordem sugerida — fase 1 (concluída)

1. **Item 1** — pequeno, destrava a suíte e o deploy. Fazer primeiro.
2. **Item 4** — a unificação de auth muda `current_user`, que todo o resto usa; melhor resolver antes de construir em cima.
3. **Item 3** — e-mail é pré-requisito para confirmação de conta e para os avisos de pagamento.
4. **Item 2** — pagamento depende de e-mail (confirmação) e de auth estável.
5. ~~**Item 5**~~ — descartado.
6. **Item 6 e 7** — concluídos.

---

## Registro de decisões

Ao marcar uma opção acima, anote aqui a data e o motivo em uma linha, para que o histórico não se perca:

| Data | Item | Decisão | Motivo |
| --- | --- | --- | --- |
| 21/09/2026 | 8 | A — Amazon S3, bucket privado | Conta AWS já necessária pelo SES; privado + URL assinada dispensa ACLs públicas |
| 19/09/2026 | 7 | Manter `docs/layouts/store/` | Referência do tema original para partes ainda não portadas |
| 19/09/2026 | 6 | A + A — remover `tax_rate` e `default_order_status` | Nunca foram lidos; imposto já vem no preço e o status inicial é sempre `pending` |
| 18/09/2026 | 5 | Não fazer | Decisão do time: estoque não será controlado pelo sistema |
| 18/09/2026 | 2 | A — Mercado Pago, Checkout Pro (redirect) | PIX, cartão e boleto no mesmo provedor, sandbox sem contrato; redirect tira a loja do escopo PCI |
| 18/09/2026 | 3 | B — Amazon SES via SMTP | Escolha do time; integração sem gem extra, mais barato em volume. Exige verificar domínio e sair do sandbox |
| 18/09/2026 | 4 | A — manter Devise | Já estava instalado e no modelo; entrega cadastro, recuperação de senha e remember-me sem código próprio |
| 18/09/2026 | 1 | A — `dartsass-rails` + Propshaft | Resolve a causa raiz (`sassc-rails` deprecado) e alinha com o padrão do Rails 8; Propshaft foi necessário para reescrever `url()` de fontes com digest |
