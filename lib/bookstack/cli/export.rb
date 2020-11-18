require "bookstack/cli/api"
require "bookstack/cli/preprocess_bookstack_posts"

module Bookstack
  module Cli
    class Export
      def self.call(resource, slug, options, api)
        records = api.public_send("#{resource}s")
        found_record = records.find { |r| r.slug == slug }
        raise "No #{resource} found with slug '#{slug}'" if found_record.nil?
        raw_export_output = api.export resource, found_record.id, type: Bookstack::Cli::Api::Type::HTML
        ext = {"pdf" => "pdf", "html" => "html", "plaintext" => "txt"}.fetch(options[:type])
        output_file_path = options[:output_file] || "#{slug}.#{ext}"
        exported_blobs = PreprocessBookstackPosts.call(slug, output_file_path, raw_export_output)
        exported_blobs.each do |blob|
          # puts [blob.file_path, blob.file_contents.size]
          # puts "#{File.dirname(blob.file_path)}: #{Dir.exist?(File.dirname(blob.file_path))}"
          output_dir = File.dirname(blob.file_path)
          FileUtils.mkdir_p output_dir unless Dir.exist?(output_dir)
          puts "Writing #{blob.file_path}"
          File.write blob.file_path, blob.file_contents
        end
        nil
      end
    end
  end
end
