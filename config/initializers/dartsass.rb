# Compila app/assets/stylesheets/application.scss em app/assets/builds/application.css.
# O Propshaft serve o arquivo gerado e reescreve os url() para os caminhos com digest.
#
# Os partials ainda usam @import, que o Dart Sass marca como deprecado (será removido
# na versão 3.0). O aviso fica silenciado até a migração para @use/@forward.
Rails.application.config.dartsass.build_options = %w[--style=compressed --no-source-map --silence-deprecation=import]
