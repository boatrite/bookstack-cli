module Bookstack
  module Cli
    class RawExport
      def self.call(resource, slug, options, api)
        records = api.public_send("#{resource}s")
        found_record = records.find { |r| r.slug == slug }
        raise "No #{resource} found with slug '#{slug}'" if found_record.nil?
        export_output = api.export resource, found_record.id, type: options[:type]
        ext = {"pdf" => "pdf", "html" => "html", "plaintext" => "txt"}.fetch(options[:type])
        filename = options[:output_file] || "#{slug}.#{ext}"
        File.write filename, export_output
      end
    end
  end
end
