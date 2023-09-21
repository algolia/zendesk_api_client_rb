module ZendeskAPI
  module Middleware
    module Response
      # Faraday middleware to handle logging
      # @private
      class Logger < Faraday::Middleware
        LOG_LENGTH = 1000

        def initialize(app, logger = nil)
          super(app)

          @logger = logger || begin
            require 'logger'
            ::Logger.new(STDOUT)
          end
        end

        def call(env)
          @app.call(env).on_complete do |env|
            unless (400..499).cover?(env[:status].to_i)
              @logger.info "#{env[:method]} [#{env[:status]}] #{env[:url].to_s} #{env[:body].to_s[0, LOG_LENGTH]}"
            end
          end
        end

        private

        def dump_debug(env, headers_key)
          info = env[headers_key].map { |k, v| "  #{k}: #{v.inspect}" }.join("\n")
          unless env[:body].nil?
            info.concat("\n")
            info.concat(env[:body].inspect)
          end
          info
        end
      end
    end
  end
end
