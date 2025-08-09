class Api::V1::EventsController < ApplicationController
    def index
        lat = params[:lat]&.to_f
        lng = params[:lng]&.to_f
        radius = params[:radius]&.to_f || 10

        events = if lat && lng
            Event.nearby(lat, lng, radius).ongoing_or_upcoming
        else
            Event.ongoing_or_upcoming
        end
        render json: events
    end

    def show
        event = Event.find(params[:id])
        render json: event
    end
end
