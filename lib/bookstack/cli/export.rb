require "bookstack/cli/api"
require "bookstack/cli/preprocess_bookstack_posts"
require "bookstack/cli/transpile_to_markdown"

module Bookstack
  module Cli
    FileBlob = Struct.new(:file_path, :file_contents, keyword_init: true)

    class Export
      def self.call(resource, slug, options, api)
        # Get all of the books or chapters
        records = api.public_send("#{resource}s")

        # Get the book or chapter based on the slug
        found_record = records.find { |r| r.slug == slug }

        # Fail right away if we didn't find it
        raise "No #{resource} found with slug '#{slug}'" if found_record.nil?

        # Get the raw html export from BookStack
        raw_export_output = api.export resource, found_record.id, type: Bookstack::Cli::Api::Type::HTML

        # Set the output file
        output_file_path = options[:output_file] || "#{slug}.md"

        # Extract the images and perform other cleanup on the raw html export.
        #
        # Returns image blobs which will be written to files as well as the
        # cleaned up html which will be converted to markdown.
        image_file_blobs, html = PreprocessBookstackPosts.call(slug, output_file_path, raw_export_output)

        write_file_blob = ->(file_blob) {
          # For debugging
          # puts [file_blob.file_path, file_blob.file_contents.size]
          # puts "#{File.dirname(file_blob.file_path)}: #{Dir.exist?(File.dirname(file_blob.file_path))}"

          # Make sure directory containing output file exists
          output_dir = File.dirname(file_blob.file_path)
          FileUtils.mkdir_p output_dir if !Dir.exist?(output_dir) && !options[:dryrun]

          # Write it to file
          already_exists = File.exist? file_blob.file_path
          puts "#{already_exists ? "Overwriting" : "Writing"} #{file_blob.file_path}#{options[:dryrun] ? " (dryrun)" : ""}"
          File.write file_blob.file_path, file_blob.file_contents unless options[:dryrun]
        }

        # Write image blobs to file
        image_file_blobs.each do |file_blob|
          write_file_blob[file_blob]
        end

        # Turn the html blob into a markdown blob
        markdown_file_blob = TranspileToMarkdown.call(slug, output_file_path, html)
        write_file_blob[markdown_file_blob]

        nil
      end
    end
  end
end
