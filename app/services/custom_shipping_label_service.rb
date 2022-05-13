class CustomShippingLabelService
  def self.perform
    new.perform
  end

  # def initialize
  # end

  def perform
    pdf_file = Rails.root.join("tmp", "shopee.pdf")
    pdf = MiniMagick::Image.open(pdf_file)

    pdf.pages.each_with_index do |page, index|
      MiniMagick::Tool::Convert.new do |convert|
        convert.background "white"
        convert.flatten
        convert.density 150
        convert.quality 100
        convert << page.path
        convert << Rails.root.join("tmp", "shipping_labels", "label-#{index}.jpg").to_s

        shipping_label_path = Rails.root.join("tmp", "shipping_labels", "label-#{index}.jpg").to_s

        shipping_label = MiniMagick::Image.open(shipping_label_path)

        image_split1_path = Rails.root.join("tmp", "shipping_labels", "qrcode-#{index}.jpg")
        shipping_label.crop "485x195+700+0-200-0"
        shipping_label.write image_split1_path

        combile_file = Rails.root.join("tmp", "shipping_labels", "combile_file-#{index}.jpg")

        composite_image = MiniMagick::Image.open(shipping_label_path)
        image = MiniMagick::Image.open(image_split1_path)
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
    end

    output_path = Rails.root.join("tmp", "output.pdf").to_s
    Prawn::Document.generate(output_path) do
      pdf.pages.count.times do |i|
        combile_file = Rails.root.join("tmp", "shipping_labels", "combile_file-#{i}.jpg")
        image combile_file, width: 580, at: [-20, 750]
        start_new_page if i < pdf.pages.count - 1
      end
    end
  end
end
