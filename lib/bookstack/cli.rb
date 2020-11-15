require "thor"
require "amazing_print"
require "httparty"
require "json"

require "bookstack/cli/version"

module Bookstack
  class Api
    class Record < OpenStruct
      def respond_to_missing?(meth, include_all)
        super
      end

      def method_missing(meth, *args)
        raise "#{meth} is not a property on the struct" unless to_h.key?(meth)
        super
      end
    end
    Collection = Struct.new(:data, :total, keyword_init: true)

    module Resource
      BOOKS = :books
      CHAPTERS = :chapters
    end

    def initialize(token_id, token_secret)
      @token_id = token_id
      @token_secret = token_secret
      raise "Missing BookStack token_id" if @token_id.nil? || @token_id.empty?
      raise "Missing BookStack token_secret" if @token_secret.nil? || @token_secret.empty?
    end

    def books
      get_resource(Resource::BOOKS).data
    end

    def chapters
      get_resource(Resource::CHAPTERS).data
    end

    def export(resource, resource_id, kind:, type:)
      response = HTTParty.get "http://localhost:8080/api/#{resource}s/#{resource_id}/export/#{type}", headers: headers
      response.body
    end

    def get_resource(resource)
      response = HTTParty.get "http://localhost:8080/api/#{resource}", headers: headers
      json = JSON.parse(response.body)
      Collection.new(
        data: json.fetch("data").map(&Record.method(:new)),
        total: json.fetch("total")
      )
    end

    def headers
      {
        "Authorization": "Token #{@token_id}:#{@token_secret}"
      }
    end
  end

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

      desc "export RESOURCE SLUG", "Export BookStack book or chapter"
      method_option :kind, aliases: "-k", desc: "'raw' or 'processed'"
      method_option :type, aliases: "-t", desc: "'pdf', 'plaintext', 'html', 'markdown'"
      def export(resource, slug)
        records = api.public_send("#{resource}s")
        found_record = records.find { |r| r.slug == slug }
        raise "No #{resource} found with slug '#{slug}'" if found_record.nil?
        puts api.export resource, found_record.id, kind: options[:kind], type: options[:type]
      end

      private

      def api
        raise "Missing BOOKSTACK_TOKEN_ID from environment" if ENV["BOOKSTACK_TOKEN_ID"].nil? || ENV["BOOKSTACK_TOKEN_ID"].empty?
        raise "Missing BOOKSTACK_TOKEN_SECRET from environment" if ENV["BOOKSTACK_TOKEN_SECRET"].nil? || ENV["BOOKSTACK_TOKEN_SECRET"].empty?

        @api ||= Bookstack::Api.new ENV["BOOKSTACK_TOKEN_ID"], ENV["BOOKSTACK_TOKEN_SECRET"]
      end
    end
  end
end

Bookstack::Cli::Main.start
