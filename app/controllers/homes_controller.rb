class HomesController < ApplicationController
  def index
  end

  def create
    file = file_params[:shipping_label_file]
    CustomShippingLabelService.perform(file)

    filename = "custom-#{file.original_filename}"
    shipping_label_path = Rails.root.join("tmp", "custom_shipping_labels", filename)
    send_data File.read(shipping_label_path), filename: filename
  end

  private

  def file_params
    params.require(:file).permit(:shipping_label_file)
  end
end
