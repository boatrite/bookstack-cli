require "open3"

require "bookstack/cli/get_bookstack_session_cookie"

module Bookstack
  module Cli
    class Api
      using RefineString

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
        PAGES = :pages
      end

      module Type
        HTML = "html"
        PLAINTEXT = "plaintext"
        PDF = "pdf"
      end

      def initialize(token_id, token_secret, firefox_profile = nil)
        @token_id = token_id
        @token_secret = token_secret
        @firefox_profile = firefox_profile
        raise "Missing BookStack token_id" if @token_id.nil? || @token_id.empty?
        raise "Missing BookStack token_secret" if @token_secret.nil? || @token_secret.empty?
      end

      def books
        get_resource(Resource::BOOKS).data
      end

      def chapters
        get_resource(Resource::CHAPTERS).data
      end

      def export(resource, resource_id, type:)
        case resource.pluralize.to_sym
        when Resource::BOOKS, Resource::CHAPTERS
          case type
          in Type::PLAINTEXT | Type::PDF | Type::HTML
            response = HTTParty.get "http://localhost:8080/api/#{resource}s/#{resource_id}/export/#{type}", headers: headers
            raise "Export request failed" unless response.ok?
            response.body
          end
        when Resource::PAGES
          # Until BookStack supports native page export (slated for v.0.31.0)
          # https://github.com/BookStackApp/BookStack/pull/2382
          # It's technically merged, but I likely won't bother updating until
          # it's officially released and the docker release is updated.
          url = "http://localhost:8080/#{resource_id}/export/html"
          response = HTTParty.get(url, headers: {"Cookie" => "bookstack_session=#{session}"})
          raise "Problem fetching page export url: '#{url}'" unless response.ok?
          response.body
        end
      end

      def download_attachment(url)
        response = HTTParty.get(url, headers: {"Cookie" => "bookstack_session=#{session}"})
        raise "Problem downloading attachment url: '#{url}'" unless response.ok?
        response.body
      end

      private

      def session
        @session ||= GetBookstackSessionCookie.call(@firefox_profile)
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
  end
end
