require "fog"
require "log4r"

module VagrantPlugins
  module AWS
    module Action
      # This action creates a DNS record
      class RegisterRoute53
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_aws::action::register_route53")
        end

        def call(env)

          # Get the configs
          config = env[:machine].provider_config

          # Get the server object
          server = env[:aws_compute].servers.get(env[:machine].id)

          # Build the DNS record options
          options = {
            :name  => config.route53_record_name,
            :type  => config.route53_record_type,
            :value => generate_value(config.route53_record_type, server),
            :ttl   => config.route53_record_ttl
          }

          # Find a zone that can host the desired record
          zone = nil
          name = options[:name]
          while !zone and name do
            name = name.split('.',2).last
            zone = env[:aws_dns].zones.select { |z| z.domain.eql? name }.first
          end

          if !zone
            raise Errors::FogError, :message => "A Hosted Zone for record '#{options[:name]}' could not be found in Route53."
          end

          # Update existing record or create a new one
          if (record = zone.records.get(options[:name]))
            if !record.type.eql?(options[:type]) or !record.value.first.eql?(options[:value])
              env[:ui].info(I18n.t("vagrant_aws.route53.replacing_record", :name => record.name))
              record.modify options
            end
          else
            env[:ui].info(I18n.t("vagrant_aws.route53.creating_record", :name => options[:name]))
            zone.records.create options
          end

          @app.call(env)
        end


        # Returns a valid record value based on record type
        def generate_value(type, server)
          case type
          when 'A'
            if server.subnet_id
              # We're in VPC
              return server.private_ip_address
            else
              # We're in EC2
              return server.public_ip_address
            end
          when 'CNAME'
            return server.dns_name
          end
        end


      end
    end
  end
end
