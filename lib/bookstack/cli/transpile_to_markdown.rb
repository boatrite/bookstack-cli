require "tempfile"
require "securerandom"

module Bookstack
  module Cli
    class TranspileToMarkdown
      def self.call(slug, output_file_path, html)
        markdown_file_blob = nil

        Tempfile.create SecureRandom.uuid do |f|
          # Parse html with Nokogiri
          doc = Nokogiri::HTML(html)

          # Update original table of contents to fix the links which are no
          # longer valid after being converted to Markdown.
          doc.css("ul.contents li").each do |li_node|
            text = li_node.text
            new_anchor_href = text.downcase.tr(" ", "-")
            anchor_node = li_node.at_css("a")
            anchor_node.set_attribute("href", "##{new_anchor_href}")
          end

          # Convert Nokogiri object back into html string
          html = doc.to_html

          # Write html to temp file
          File.write f.path, html

          # Get markdown conversion of the html file
          command = "reverse_markdown #{f.path} --github-flavored=true"
          markdown_contents = `#{command}`.strip

          markdown_file_blob = FileBlob.new(file_path: output_file_path, file_contents: markdown_contents)
        end

        markdown_file_blob
      end
    end
  end
end
