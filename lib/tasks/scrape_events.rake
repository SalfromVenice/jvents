require "open-uri"
require "nokogiri"


namespace :scrape do
    desc "Scrape eventi da sito esterno"
    task events: :environment do
        today = Date.today
        from_date = today.strftime("%Y-%m-%d")
        to_date = (today + 7).strftime("%Y-%m-%d")
        base_url  = ENV["BASE_URL"]
        endpoint = "/events?type=event&prefecture=Tokyo&from=#{from_date}&to=#{to_date}&p="
        first_page_html = URI.open("#{base_url}#{endpoint}1")
        first_doc = Nokogiri::HTML(first_page_html)

        total_events_found = first_doc.at_css("div.container div.row span.results.left-section-title span")&.text&.to_i
        last_page = (total_events_found / 8.0).ceil
        events_counter = 0

        puts "Totale eventi: #{total_events_found}"
        (1..last_page).each do |page|
            url = base_url + endpoint + page.to_s
            html = URI.open(url)
            doc = Nokogiri::HTML(html)

            doc.css("section.event-searched-results a.article-item-link").each do |event_div|
                begin
                    event_link = event_div&.[]("href")
                    next unless event_link
                    details_url = URI.join(base_url, event_link).to_s
                    detail_html = URI.open(details_url)
                    detail_doc = Nokogiri::HTML(detail_html)

                    venue = detail_doc.at_css("div.venue-name")&.text&.strip
                    event_url = detail_doc.at_css("div.website.col-xs-12 a")&.[]("href")
                    address_div = detail_doc.at_css("div.address.event.col-xs-12")
                    raw_address = address_div.at_css("p")&.children&.select { |n| n.text? }&.map(&:text)&.join&.strip
                    # => rimuove tutte le parentesi vuote "()"
                    address = raw_address&.gsub(/\(\s*\)/, "").strip
                    # sostituisce spazi multipli con uno solo
                    address = address&.gsub(/\s+/, " ")
                    directions_link = address_div.at_css('a[href*="google.com/maps"]')&.[]("href")

                    lat_lng = nil
                    if directions_link
                        # Estraggo le coordinate lat,lng dall'href es. https://google.com/maps?daddr=35.7970394,139.5070773&dirflg=r
                        query = URI.parse(directions_link).query
                        params = URI.decode_www_form(query).to_h
                        lat_lng = params["daddr"]  # stringa "35.7970394,139.5070773"
                    end

                    lat, lng = lat_lng&.split(",")

                    title = event_div.at_css(".event-item__title")&.text&.strip
                    cost =  event_div.at_css(".event-item__ticket")&.text&.strip
                    # Rimuovo eventuali icone o spazi
                    cost = cost&.gsub(/\s*[\uF000-\uFFFF]*/, "").strip
                    start_date = event_div.at_css("time[itemprop='startDate']")&.[]("datetime")
                    end_date = event_div.at_css("time[itemprop='endDate']")&.[]("datetime")
                    image_src = event_div.at_css("img.event-item__image")&.[]("src")
                    image_url = image_src ? URI.join(base_url, image_src).to_s : nil

                    # puts "Titolo: #{title}"
                    # puts "start date: #{start_date}"
                    # puts "end date: #{end_date}"
                    # puts "Image: #{image_url}"
                    # puts "Cost: #{cost}"
                    # puts "Venue: #{venue}"
                    # puts "Address: #{address}"
                    # puts "Coordinates: #{lat} & #{lng}"
                    # puts "Sito: #{event_url}"

                    # Event.create(
                    #     title: title,
                    #     address: address,
                    #     start_time: start_date,
                    #     end_time: end_date,
                    #     image_url: image_url,
                    #     venue: venue,
                    #     cost: cost,
                    #     latitude: lat,
                    #     longitude: lng,
                    #     url: event_url
                    # )

                    Event.find_or_create_by(title: title, start_time: start_date, address: address) do |event|
                        event.end_time = end_date
                        event.cost = cost
                        event.image_url = image_url
                        event.venue = venue
                        event.latitude = lat
                        event.longitude = lng
                        event.url = event_url
                    end

                    events_counter += 1
                    puts "#{events_counter}/#{total_events_found}"

                    # pausa casuale tra 1 e 3 secondi
                    sleep(rand(1..3))
                rescue StandardError => e
                    puts "Errore durante il parsing dell'evento: #{e.message}"
                end
            end
        end
    end
    puts "Finito!"
end
