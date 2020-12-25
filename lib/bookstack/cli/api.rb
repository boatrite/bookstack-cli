require "open3"

module Bookstack
  module Cli
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
        case resource
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

          # Create a file to cache session in so we don't have to fetch it
          # every time this script runs
          #
          # If the file is not present or the cookie is expired, refetch (this
          # will require closing firefox)
          cache_dir = File.expand_path File.join __dir__, "../../../cache/"
          FileUtils.mkdir_p cache_dir unless Dir.exist? cache_dir
          session_cache_file = File.join(cache_dir, ".session-cache")

          generate_session_cache_file = -> {
            raise "Environment variable FIREFOX_PROFILE not set" if @firefox_profile.nil?
            command = %(sqlite3 -line ~/.mozilla/firefox/#{@firefox_profile}/cookies.sqlite "SELECT value, expiry FROM moz_cookies WHERE name = 'bookstack_session';" | sed -s 's/ //g')
            contents, error, _status = Open3.capture3 command
            if error != ""
              puts "*** ERROR OCCURRED, TERMINATING ***"
              puts "*** THE ERROR: ***"
              puts error
              abort
            end
            File.write session_cache_file, contents
            puts "Wrote new session cache file"
          }

          if File.exist? session_cache_file
            puts "Found .session-cache"
            expiry = `grep expiry < #{session_cache_file} | cut -d'=' -f2`.to_i
            if expiry < Time.now.to_i
              puts "Cookie is expired, attempting to fetch new one"
              generate_session_cache_file.call
            else
              puts "Cookie is valid"
            end
          else
            puts "Missing .session-cache. Attempting to fetch new one"
            generate_session_cache_file.call
          end

          session = `grep value < #{session_cache_file} | cut -d'=' -f2`.strip

          url = "http://localhost:8080/#{resource_id}/export/html"
          command = %(curl '#{url}' --silent -H "Cookie: bookstack_session=#{session}")
          `#{command}`
        end
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
