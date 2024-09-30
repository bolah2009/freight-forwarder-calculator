module Api
  module V1
    class ShipmentsController < ApplicationController
      before_action :validate_params, only: %i[create]

      def create
        origin_port = params[:origin_port]
        destination_port = params[:destination_port]
        criteria = params[:criteria]
        processor = ShipmentProcessor.new(
          origin_port:,
          destination_port:,
          criteria:
        )

        result = processor.process

        render json: Array.wrap(result), status: :ok
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def validate_params
        return if params[:origin_port].present? && params[:destination_port].present? && params[:criteria].present?

        render json: { error: "Missing required parameters" }, status: :unprocessable_entity
      end
    end
  end
end
