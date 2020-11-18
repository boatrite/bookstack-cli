module Bookstack
  module Cli
    class Export
      def self.call(resource, slug, options, api)
        records = api.public_send("#{resource}s")
        found_record = records.find { |r| r.slug == slug }
        raise "No #{resource} found with slug '#{slug}'" if found_record.nil?
        raw_export_output = api.export resource, found_record.id, type: options[:type]
        # Turns the raw single-file export from BookStack into a collection of
        # [file_path, file_contents] pairs which will be persisted.
        exported_blobs = ->(raw_export_output) {
          ext = {"pdf" => "pdf", "html" => "html", "plaintext" => "txt"}.fetch(options[:type])
          filename = options[:output_file] || "#{slug}.#{ext}"

          [
            [filename, raw_export_output.size]
          ]
        }
        puts exported_blobs[raw_export_output]
        # exported_blobs[raw_export_output].each do |exported_blob|
        # File.write exported_blob.path, exported_blob.contents
        # end
        # File.write filename, output
      end
    end
  end
end
