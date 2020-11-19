require "thor"
require "amazing_print"
require "httparty"
require "json"

require "bookstack/cli/api"
require "bookstack/cli/export"
require "bookstack/cli/raw_export"
require "bookstack/cli/version"

module Bookstack
  module Cli
    class Error < StandardError; end

    class Main < Thor
      desc "books", "List all books"
      def books
        ap api.books
      end

      desc "chapters", "List all chapters"
      def chapters
        ap api.chapters
      end

      desc "raw_export RESOURCE SLUG", "Export book or chapter directly from BookStack"
      method_option :type, aliases: "-t", desc: "'pdf', 'plaintext', 'html'"
      method_option :output_file, aliases: "-of", desc: "Where to save exported file"
      def raw_export(resource, slug)
        RawExport.call resource, slug, options, api
      end

      desc "export RESOURCE SLUG", "Export BookStack book or chapter"
      method_option :output_file, aliases: "-of", desc: "Where to save main export file"
      method_option :dryrun, desc: "Show output without actually making changes"
      def export(resource, slug)
        Export.call resource, slug, options, api
      end

      private

      def api
        raise "Missing BOOKSTACK_TOKEN_ID from environment" if ENV["BOOKSTACK_TOKEN_ID"].nil? || ENV["BOOKSTACK_TOKEN_ID"].empty?
        raise "Missing BOOKSTACK_TOKEN_SECRET from environment" if ENV["BOOKSTACK_TOKEN_SECRET"].nil? || ENV["BOOKSTACK_TOKEN_SECRET"].empty?

        @api ||= Bookstack::Cli::Api.new ENV["BOOKSTACK_TOKEN_ID"], ENV["BOOKSTACK_TOKEN_SECRET"]
      end
    end
  end
end

Bookstack::Cli::Main.start
