require "faraday/middleware"
module ZendeskAPI
  module Middleware
    class RetriableResponse < Faraday::Error
    end

    # @private
    module Request
      # Faraday middleware to handle HTTP Status 429 (rate limiting) / 503 (maintenance)
      # @private
      class Retry < Faraday::Middleware
        DEFAULT_RETRY_AFTER = 10
        DEFAULT_MAX_RETRIES = 10
        DEFAULT_ERROR_CODES = [429, 503]

        def initialize(app, options = {})
          super(app)
          @logger = options[:logger]
          @error_codes = options.key?(:retry_codes) && options[:retry_codes] ? options[:retry_codes] : DEFAULT_ERROR_CODES
          @retry_on_exception = options.key?(:retry_on_exception) && options[:retry_on_exception] ? options[:retry_on_exception] : false
        end

        def rewind_files(body)
          return unless defined?(UploadIO)
          return unless body.is_a?(Hash)

          body.each do |_, value|
            value.rewind if value.is_a?(UploadIO)
          end
        end

        def call(env)
          original_env = env.dup
          exception_happened = false
          retries = 0

          body = env[:body]

          begin
            env[:body] = body
            @app.call(env).tap do |resp|
              raise ZendeskAPI::Middleware::RetriableResponse.new(nil, resp) if @error_codes.include?(resp.status)
            end
          rescue => e
            if e.response && @error_codes.include?(e.response.env[:status])
              seconds_left = (e.response.env[:response_headers][:retry_after] || DEFAULT_RETRY_AFTER).to_i
              @logger.warn "\t[retry #{retries}/#{DEFAULT_MAX_RETRIES}] You have been rate limited. Retrying in #{seconds_left} seconds..." if @logger
            else
              seconds_left = DEFAULT_RETRY_AFTER.to_i
              @logger.warn "\t[retry #{retries}/#{DEFAULT_MAX_RETRIES}] An exception happened, waiting #{seconds_left} seconds... #{e}" if @logger
            end

            rewind_files(body)

            seconds_left.times do |i|
              sleep 1
              time_left = seconds_left - i
            end

            if retries < DEFAULT_MAX_RETRIES
              retry
            else
              raise Error::NetworkError.new(e, env)
            end

            retries += 1
          end
        end
      end
    end
  end
end
