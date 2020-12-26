module Bookstack
  module Cli
    class GetBookstackSessionCookie
      def self.call(firefox_profile)
        # Create a file to cache session in so we don't have to fetch it
        # every time this script runs
        #
        # If the file is not present or the cookie is expired, refetch (this
        # will require closing firefox)
        cache_dir = File.expand_path File.join __dir__, "../../../cache/"
        FileUtils.mkdir_p cache_dir unless Dir.exist? cache_dir
        session_cache_file = File.join(cache_dir, ".session-cache")

        generate_session_cache_file = -> {
          raise "Environment variable FIREFOX_PROFILE not set" if firefox_profile.nil?
          command = %(sqlite3 -line ~/.mozilla/firefox/#{firefox_profile}/cookies.sqlite "SELECT value, expiry FROM moz_cookies WHERE name = 'bookstack_session';" | sed -s 's/ //g')
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

        `grep value < #{session_cache_file} | cut -d'=' -f2`.strip
      end
    end
  end
end
