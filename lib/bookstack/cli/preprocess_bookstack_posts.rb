require "nokogiri"

module Bookstack
  module Cli
    class PreprocessBookstackPosts
      IMAGE_URL_REGEX = /(http:\/\/localhost:8080)?\/uploads\/images\/gallery\/\d{4}-\d{2}(?:-\w{3})?\/[a-zA-Z0-9_\-.]+/
      IMAGE_NAME_REGEX = /(http:\/\/localhost:8080)?\/uploads\/images\/gallery\/\d{4}-\d{2}(?:-\w{3})?\/\K[a-zA-Z0-9_\-.]+/

      DATA_REGEX = /data:image\/[^;]*;base64,[a-zA-Z0-9+\/=]*/
      BASE64_REGEX = /data:image\/[^;]*;base64,\K[a-zA-Z0-9+\/=]*/

      def self.call(slug, output_file_path, raw_export_output, options)
        # Get directory of output file
        output_dir = File.dirname(output_file_path)

        # Initialize return variable
        image_file_blobs = []

        # Replace windows line endings
        raw_export_output.gsub!("\r\n", "\n")

        # Nokogiri helper
        collect_until_css_class = ->(first, css_class) {
          return [] if first.next.nil?
          first.attributes["class"]&.value == css_class ?
          [first] :
          [first, *collect_until_css_class.call(first.next, css_class)]
        }

        html = raw_export_output

        doc = Nokogiri::HTML(html)

        # Remove any of my tags in the title
        title_heading = doc.at_css(".page-content h1")
        title_heading.content = title_heading.content.gsub(/\[.+?\] /, "")

        denylist = %w[SkipExport Draft]
        denylist.each do |denyword|
          # Remove chapters whose title contains "<denyword>".
          skip_headers = doc.css("h1:contains('#{denyword}')")
          skip_headers.each do |header_node|
            nodes_to_delete = collect_until_css_class.call(header_node, "page-break")
            nodes_to_delete.each(&:remove)
          end

          # Remove ToC links for removed chapters
          doc.css("a:contains('#{denyword}')").map(&:parent).each(&:remove)
        end

        # Remove trailing page break (displays as horizontal lines).
        last_element = doc.at_css(".page-content").children.reverse.find(&:element?)
        if last_element&.attributes&.[]("class")&.value == "page-break"
          last_element.remove
        end

        # Remove metadata
        metadata_element = doc.at_css(".entity-meta")
        if metadata_element
          wrapper_element = metadata_element.parent
          preceding_hr_element = wrapper_element.previous_element
          raise "proceding_hr_element is not actually an HR." unless preceding_hr_element.name == "hr"
          preceding_hr_element.remove
          wrapper_element.remove
        end

        html = doc.to_html

        # Extract the images
        #
        # In particular, do this after clearing out filtered sections so that we
        # don't extract images for parts that have been removed.
        html = html.split("\n").map { |html_line|
          image_match = html_line.match(IMAGE_NAME_REGEX)
          if image_match
            image_name = image_match[0]

            base64_match = html_line.match(BASE64_REGEX)
            raise "Found bookstack image but no base64" unless base64_match
            base64 = base64_match[0]

            local_image_dir = options[:output_dir] || slug
            local_image_path = File.join local_image_dir, image_name

            image_file_blobs << FileBlob.new(
              file_path: File.join(output_dir, local_image_path),
              file_contents: Base64.decode64(base64)
            )

            new_html_line = html_line
              .sub(IMAGE_URL_REGEX, local_image_path)
              .sub(DATA_REGEX, local_image_path)

            new_html_line
          else
            html_line
          end
        }.map(&:rstrip).join("\n")

        [image_file_blobs, html]
      end
    end
  end
end
