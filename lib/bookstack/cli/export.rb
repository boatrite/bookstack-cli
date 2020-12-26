require "digest"

require "bookstack/cli/api"
require "bookstack/cli/convert_markdown_to_markdeep"
require "bookstack/cli/preprocess_bookstack_posts"
require "bookstack/cli/transpile_to_markdown"

module Bookstack
  module Cli
    FileBlob = Struct.new(:file_path, :file_contents, keyword_init: true)

    class Export
      using RefineString

      def self.call(resource, slug, options, api)
        case resource.pluralize.to_sym
        when Api::Resource::BOOKS, Api::Resource::CHAPTERS
          # Get all of the books or chapters
          records = api.public_send("#{resource}s")

          # Get the book or chapter based on the slug
          found_record = records.find { |r| r.slug == slug }

          # Fail right away if we didn't find it
          raise "No #{resource} found with slug '#{slug}'" if found_record.nil?

          # Get the raw html export from BookStack
          raw_export_output = api.export resource, found_record.id, type: Bookstack::Cli::Api::Type::HTML
        when Api::Resource::PAGES
          # Until BookStack supports native page export (slated for v.0.31.0)
          # https://github.com/BookStackApp/BookStack/pull/2382
          # It's technically merged, but I likely won't bother updating until
          # it's officially released and the docker release is updated.

          # To get this working, the api.export method already special cases
          # PAGES, so we just call the export method in this particular way and
          # we'll get the hacky code path for the page html export

          # Get the raw html export from BookStack
          raw_export_output = api.export resource, slug, type: Bookstack::Cli::Api::Type::HTML

          # We need to redefine slug since it's used in the naming for
          # extracted images as well as possibly the final output filename.
          # e.g. 'books/blog-posts/page/game-boy-advance-development-with-mruby'
          # to 'game-boy-advance-development-with-mruby'
          # If we don't do this, we end up creating extra directories 'books',
          # 'blog-posts', and 'page'
          slug = slug.split("/").last
        end

        # Set the output file
        output_file_path = options[:output_file] || "#{slug}.#{options[:html] ? "html" : "md"}"

        # Extract the images and perform other cleanup on the raw html export.
        #
        # Returns image blobs which will be written to files as well as the
        # cleaned up html which will be converted to markdown.
        image_file_blobs, html = PreprocessBookstackPosts.call(slug, output_file_path, raw_export_output, options)

        write_file_blob = ->(file_blob) {
          # For debugging
          # puts [file_blob.file_path, file_blob.file_contents.size]
          # puts "#{File.dirname(file_blob.file_path)}: #{Dir.exist?(File.dirname(file_blob.file_path))}"

          # Make sure directory containing output file exists
          output_dir = File.dirname(file_blob.file_path)
          FileUtils.mkdir_p output_dir if !Dir.exist?(output_dir) && !options[:dryrun]

          # Write it to file
          already_exists = File.exist? file_blob.file_path
          dryrun_label = options[:dryrun] ? " (dryrun)" : ""
          if already_exists
            new_digest = Digest::SHA256.hexdigest file_blob.file_contents
            old_digest = Digest::SHA256.hexdigest File.read file_blob.file_path
            is_same_digest = new_digest == old_digest
            if is_same_digest
              puts "Skipping since unchanged #{file_blob.file_path}#{dryrun_label}"
            else
              puts "Overwriting #{file_blob.file_path}#{dryrun_label}"
              File.write file_blob.file_path, file_blob.file_contents unless options[:dryrun]
            end
          else
            puts "Writing #{file_blob.file_path}#{dryrun_label}"
            File.write file_blob.file_path, file_blob.file_contents unless options[:dryrun]
          end
        }

        # Write image blobs to file
        image_file_blobs.each do |file_blob|
          write_file_blob[file_blob]
        end

        # Possibly turn the html blob into a markdown blob.
        # Save final blob to file
        if options[:html]
          html_file_blob = FileBlob.new(file_path: output_file_path, file_contents: html)
          write_file_blob[html_file_blob]
        else
          markdown_file_blob = TranspileToMarkdown.call(slug, output_file_path, html)

          if options[:markdeep]
            markdeep_file_blob = ConvertMarkdownToMarkdeep.call(markdown_file_blob, options[:markdeep])
            write_file_blob[markdeep_file_blob]
          else
            write_file_blob[markdown_file_blob]
          end
        end

        nil
      end
    end
  end
end
