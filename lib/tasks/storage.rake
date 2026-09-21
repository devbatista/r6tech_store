namespace :storage do
  desc "Copia os blobs do Active Storage de um serviço para outro (FROM=local TO=amazon) e atualiza service_name"
  task migrate: :environment do
    from_name = ENV.fetch("FROM", "local")
    to_name = ENV.fetch("TO", "amazon")
    services = ActiveStorage::Blob.services
    from = services.fetch(from_name.to_sym)
    to = services.fetch(to_name.to_sym)

    blobs = ActiveStorage::Blob.where(service_name: from_name)
    puts "Migrando #{blobs.count} blob(s) de #{from_name} para #{to_name}..."

    migrated = 0
    blobs.find_each do |blob|
      unless from.exist?(blob.key)
        puts "  pulando #{blob.key} (#{blob.filename}): arquivo não encontrado em #{from_name}"
        next
      end

      from.open(blob.key, checksum: blob.checksum) do |file|
        to.upload(blob.key, file, checksum: blob.checksum, content_type: blob.content_type)
      end
      blob.update_column(:service_name, to_name)
      migrated += 1
      print "."
    end

    puts "\n#{migrated} blob(s) migrado(s). Variantes serão regeradas sob demanda no novo serviço."
  end
end
