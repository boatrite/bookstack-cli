require "tempfile"
require "securerandom"

module Bookstack
  module Cli
    class TranspileToMarkdown
      def self.call(slug, output_file_path, html)
        markdown_file_blob = nil

        Tempfile.create SecureRandom.uuid do |f|
          tmp_html_path = f.path
          File.write tmp_html_path, html
          command = "reverse_markdown #{tmp_html_path} --github-flavored=true"
          markdown_contents = `#{command}`.strip
          markdown_file_blob = FileBlob.new(file_path: output_file_path, file_contents: markdown_contents)
        end

        markdown_file_blob
      end
    end
  end
end
