class ScrapeEventsJob < ApplicationJob
  queue_as :default

  def perform
    Rake::Task["scrape:events"].reenable
    Rake::Task["scrape:events"].invoke
  end
end
