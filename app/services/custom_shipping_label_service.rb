class CustomShippingLabelService
  def self.perform(file)
    new(file).perform
  end

  def initialize(file)
    @file = file
  end

  attr_reader :file

  def perform
    file_key = file.original_filename.gsub(".pdf", "")
    pdf = MiniMagick::Image.open(file.path)

    pdf.pages.each.with_index do |page, index|
      MiniMagick::Tool::Convert.new do |convert|
        convert.background "white"
        convert.flatten
        convert.density 150
        convert.quality 100
        convert << page.path
        convert << Rails.root.join("tmp", "shipping_labels", "label-#{file_key}-#{index}.jpg").to_s
      end

      shipping_label_path = Rails.root.join("tmp", "shipping_labels", "label-#{file_key}-#{index}.jpg").to_s
      shipping_label = MiniMagick::Image.open(shipping_label_path)

      qrcode_file_path = Rails.root.join("tmp", "shipping_labels", "qrcode-#{file_key}-#{index}.jpg")
      shipping_label.crop "510x195+670+0-200-0"
      shipping_label.write qrcode_file_path

      combile_file = Rails.root.join("tmp", "shipping_labels", "combile_file-#{file_key}-#{index}.jpg")

      composite_image = MiniMagick::Image.open(shipping_label_path)
      image = MiniMagick::Image.open(qrcode_file_path)
      image.resize("700x")

      image.layers.count.times do |i|
        composite_image = composite_image.composite(image.layers[i]) do |c|
          c.compose "Over" # OverCompositeOp
          c.geometry "+250+1300"
        end
      end

      composite_image.quality(85)
      composite_image.write(combile_file)
    end

    output_filename = "custom-#{file.original_filename}"
    output_path = Rails.root.join("tmp", "custom_shipping_labels", output_filename).to_s
    Prawn::Document.generate(output_path, page_size: "A4") do
      pdf.pages.count.times do |index|
        combile_file = Rails.root.join("tmp", "shipping_labels", "combile_file-#{file_key}-#{index}.jpg")
        image combile_file, width: 600, at: [-35, 800]
        start_new_page if index < pdf.pages.count - 1
      end
    end
  end
end
