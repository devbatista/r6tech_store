# Checklist de Desenvolvimento

Pendências identificadas na análise do projeto em 18/09/2026, organizadas por prioridade. Cada item traz as tarefas e, quando há mais de um caminho possível, as opções com uma recomendação. Marque a opção escolhida em **Decisão** antes de começar a implementação, para que o histórico da escolha fique registrado aqui.

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
- [ ] Revisar `storefront.css:46`: `width: min(650px, ...)` junto com `min-width: 650px` se contradizem; definir o comportamento desejado no mobile
- [x] Rodar `bundle exec rspec` e confirmar 0 falhas
- [x] Rodar `RAILS_ENV=production bin/rails assets:precompile` localmente para confirmar que o build passa
- [ ] Adicionar `assets:precompile` ao pipeline de CI (ou ao `Dockerfile`) para que isso não volte a passar despercebido
- [ ] Migrar os partials SCSS de `@import` para `@use`/`@forward` (o Dart Sass 3.0 vai remover `@import`; o aviso está silenciado em `config/initializers/dartsass.rb`)
- [ ] Decidir o destino de `app/assets/stylesheets/scss/app.scss`: não é entrypoint nem é importado por ninguém

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
- [ ] Remover `spec/test_helper.rb`, `spec/application_system_test_case.rb`, `spec/channels/` e `spec/fixtures/*.yml`: sobras do Minitest que o RSpec não carrega

**Comportamento que mudou:**

- Um usuário removido do banco enquanto logado agora vira visitante anônimo (padrão do Devise), em vez de receber o aviso "sessão expirada".
- `GET /users/edit` (edição de conta do Devise) redireciona para a página da conta, que já cuida de perfil e senha.

---

## 🟠 5. Controle de estoque

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

## 🟠 6. Configurações salvas mas ignoradas

**Problema:** `tax_rate` e `default_order_status` são editáveis em `/admin/settings/shipping`, gravados em `Setting` e nunca lidos.

**Decisão — o que fazer com cada campo:**

- `tax_rate`
  - [ ] **A. Remover campo e coluna** (recomendado)
    No Brasil o imposto já está embutido no preço; uma taxa separada confunde o cliente.
  - [ ] **B. Aplicar no total do pedido**
    Somar `subtotal * tax_rate` em `Order.create_from_cart!` e mostrar a linha no carrinho e no pedido.
- `default_order_status`
  - [ ] **A. Remover campo e coluna** (recomendado)
    O status inicial de um pedido é sempre `pending`; deixar configurável permite quebrar as transições de `STATUS_TRANSITIONS`.
  - [ ] **B. Usar em `Order.create_from_cart!`**
    Só faz sentido se houver um caso real, como loja que aceita pedido sem pagamento online.

**Tarefas:**

- [ ] Aplicar as decisões (migration de remoção ou uso real)
- [ ] Atualizar `Admin::Settings::ShippingController` e a view correspondente
- [ ] Atualizar specs de settings

---

## 🟡 7. Limpeza e dívida técnica

- [ ] **`products.price` obrigatório mesmo com variações**
  O form esconde o campo quando há variação, mas a validação `presence: true` continua em `Product`. Tornar condicional (`unless: -> { product_variants.any? }`) ou preencher automaticamente com o menor preço das variantes.
- [ ] **Remover `app/javascript/controllers/hello_controller.js`** e a linha correspondente em `controllers/index.js`
- [ ] **`docs/layouts/store/`** — template HTML original do tema, com Bootstrap, Swiper etc.
  - [ ] **A. Remover do repositório** (recomendado)
    Já foi portado para `app/views/storefront` e `app/assets`. Guardar o zip original fora do repo se quiser referência.
  - [ ] **B. Manter**
    Só se ainda for consultar páginas do tema que não foram portadas.
- [ ] **Renomear `db/seeds/5-products.rb` → `6-products.rb`** para a sequência ficar contínua
- [ ] **Preencher ou remover `spec/models/storage_spec.rb`** (está vazio, 1 pending)
- [ ] **Verificar `config/locales/pt-BR.yml`** — "Metodos de pagamento" está sem acento nas chaves `payment_methods` e `payment_methods_hint` (contraria `spec/agents/system_specifications.md`)
- [ ] **Assets do admin** — `app/assets/javascripts` inclui jQuery, Morris, Raphael, jVectorMap e vários `line-chart-*.js`; verificar quais o dashboard realmente usa e remover o resto

---

## Ordem sugerida

1. **Item 1** — pequeno, destrava a suíte e o deploy. Fazer primeiro.
2. **Item 4** — a unificação de auth muda `current_user`, que todo o resto usa; melhor resolver antes de construir em cima.
3. **Item 3** — e-mail é pré-requisito para confirmação de conta e para os avisos de pagamento.
4. **Item 2** — pagamento depende de e-mail (confirmação) e de auth estável.
5. **Item 5** — estoque depende de pagamento para saber quando baixar.
6. **Item 6 e 7** — podem ser intercalados a qualquer momento; são pequenos e independentes.

---

## Registro de decisões

Ao marcar uma opção acima, anote aqui a data e o motivo em uma linha, para que o histórico não se perca:

| Data | Item | Decisão | Motivo |
| --- | --- | --- | --- |
| 18/09/2026 | 2 | A — Mercado Pago, Checkout Pro (redirect) | PIX, cartão e boleto no mesmo provedor, sandbox sem contrato; redirect tira a loja do escopo PCI |
| 18/09/2026 | 3 | B — Amazon SES via SMTP | Escolha do time; integração sem gem extra, mais barato em volume. Exige verificar domínio e sair do sandbox |
| 18/09/2026 | 4 | A — manter Devise | Já estava instalado e no modelo; entrega cadastro, recuperação de senha e remember-me sem código próprio |
| 18/09/2026 | 1 | A — `dartsass-rails` + Propshaft | Resolve a causa raiz (`sassc-rails` deprecado) e alinha com o padrão do Rails 8; Propshaft foi necessário para reescrever `url()` de fontes com digest |
