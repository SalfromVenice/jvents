namespace :events do
    desc "Delete expired events"

    task delete_expired: :environment do
        deleted_count = Event.delete_expired!
        puts "#{deleted_count} eventi scaduti eliminati."
    end
end
