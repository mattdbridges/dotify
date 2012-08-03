module Dotify
  VERSION = "0.6.6"

  class Version
    class << self
      def run_check!
        require 'multi_json'
        return if !@version.nil?

        resp = Net::HTTP.get('rubygems.org', '/api/v1/versions/dotify.json')
        json = MultiJson.load(resp)
        @version = json.map { |v| v['number'] }.max
      end

      def to_s
        VERSION
      end

      def current?
        VERSION == self.version
      end

      def out_of_date?
        !current?
      end

      def version
        @version || self.run_check!
      end

      def handle_error(e)
        "Version Check Error: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end

end
