class Event < ApplicationRecord
    validates :title, presence: true
    validates :start_time, presence: true
    validates :address, presence: true
    validates :image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

    scope :upcoming, -> { where("start_time >= ?", Time.current).order(:start_time) }
    scope :expired, ->  { where("end_time < ?", Time.current) }

    # formula di Haversine (o una sua variante),
    # calcola la distanza tra due punti sulla superficie della Terra,
    # usando latitudine e longitudine.
    def self.nearby(lat, lng, radius_km = 10)
        where.not(latitude: nil, longitude: nil)
        .where(%{
            6371 * acos(
                cos(radians(?)) * cos(radians(latitude)) *
                cos(radians(longitude) - radians(?)) +
                sin(radians(?)) * sin(radians(latitude))
            ) < ?
        }, lat, lng, lat, radius_km)
    end

    def self.delete_expired!
        expired.delete_all
    end
end
