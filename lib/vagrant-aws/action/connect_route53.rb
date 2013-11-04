require "fog"
require "log4r"

module VagrantPlugins
  module AWS
    module Action
      # This action connects to Route53 using the AWS providers credentials
      class ConnectRoute53
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_aws::action::connect_route53")
        end

        def call(env)

          # Get the configs
          config = env[:machine].provider_config

          # Build the fog config
          fog_config = { :provider => :aws }

          fog_config[:aws_access_key_id]     = config.access_key_id
          fog_config[:aws_secret_access_key] = config.secret_access_key

          fog_config[:endpoint] = config.endpoint if config.endpoint
          fog_config[:version]  = config.version if config.version

          @logger.info("Connecting to Route53...")
          env[:aws_dns] = Fog::DNS.new(fog_config)

          @app.call(env)
        end
      end
    end
  end
end
