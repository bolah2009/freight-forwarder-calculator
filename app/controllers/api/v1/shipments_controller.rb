class Api::V1::ShipmentsController < ApplicationController
  before_action :require_params_presence, only: %i[create]

  def create
    origin_port = params[:origin_port]
    destination_port = params[:destination_port]
    criteria = params[:criteria]
    # criteria = "cheapest-direct"
    # destination_port = "NLRTM"
    # origin_port = "CNSHA"
    processor = ShipmentProcessor.new(
      origin_port: origin_port,
      destination_port: destination_port,
      criteria: criteria
    )

    result = processor.process

    render json: Array.wrap(result), status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def require_params_presence
   return if  params[:origin_port].present? && params[:destination_port].present? && params[:criteria].present?

   render json: { error: "Missing required parameters" }, status: :unprocessable_entity
  end
end
