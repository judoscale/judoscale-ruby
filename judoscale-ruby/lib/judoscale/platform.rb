# frozen_string_literal: true

module Judoscale
  # The hosting platform we detected from the environment. The container/instance
  # id is just one property of the platform — behavior that only applies to
  # certain platforms (whether an instance is a redundant member of a formation,
  # or an ephemeral process) lives on the platform subclasses that actually have
  # those concepts, instead of being re-derived from the shape of the container
  # string.
  class Platform
    attr_reader :container

    def initialize(container)
      @container = container.to_s
    end

    # Most platforms expose opaque, non-ordinal instance ids (Render, ECS, Fly,
    # Railway, custom), so by default no instance is redundant or ephemeral.
    # Platforms that have those concepts override these.
    def redundant_instance?
      false
    end

    def ephemeral_instance?
      false
    end

    # Platforms may contribute a default API base url when one isn't configured.
    def default_api_base_url
      nil
    end

    # Detect the current platform from the environment. Order matters: an explicit
    # JUDOSCALE_CONTAINER always wins, and Unknown is the fallback.
    def self.detect(env = ENV)
      if env.include?("JUDOSCALE_CONTAINER")
        Custom.new env["JUDOSCALE_CONTAINER"]
      elsif env.include?("DYNO")
        Heroku.new env["DYNO"]
      elsif env.include?("RENDER_INSTANCE_ID")
        Render.new env["RENDER_INSTANCE_ID"], service_id: env["RENDER_SERVICE_ID"]
      elsif env.include?("ECS_CONTAINER_METADATA_URI")
        Ecs.new env["ECS_CONTAINER_METADATA_URI"].split("/").last
      elsif env.include?("FLY_MACHINE_ID")
        Fly.new env["FLY_MACHINE_ID"]
      elsif env.include?("RAILWAY_REPLICA_ID")
        Railway.new env["RAILWAY_REPLICA_ID"]
      elsif env.include?("CONTAINER")
        # Scalingo exposes the container type and index (e.g. "web-1") via CONTAINER.
        Scalingo.new env["CONTAINER"]
      else
        Unknown.new ""
      end
    end

    # Heroku dynos are named "web.2". We collect job metrics from a single
    # container per process type, so any instance beyond the first is redundant —
    # it would only duplicate the queue metrics the first instance already reports.
    class Heroku < Platform
      def redundant_instance?
        match = container.match(/\A[a-z_]+\.(\d+)\z/)
        match ? match[1].to_i > 1 : false
      end

      # Heroku release phase and one-off dynos are named "release.1234" and "run.1234".
      def ephemeral_instance?
        container.downcase.start_with?("release.") || container.start_with?("run.")
      end
    end

    # Scalingo containers are named "web-2", same redundancy rule as Heroku.
    class Scalingo < Platform
      def redundant_instance?
        match = container.match(/\A[a-z_]+-(\d+)\z/)
        match ? match[1].to_i > 1 : false
      end

      # Scalingo one-off containers are named "one-off-1234".
      def ephemeral_instance?
        container.start_with?("one-off-")
      end
    end

    class Render < Platform
      def initialize(instance_id, service_id:)
        @service_id = service_id
        # Render prefixes the instance id with the service id, which isn't part of the instance.
        super(instance_id.delete_prefix("#{service_id}-"))
      end

      # Legacy Render services not using JUDOSCALE_URL derive the adapter URL
      # from the service id.
      def default_api_base_url
        "https://adapter.judoscale.com/api/#{@service_id}"
      end
    end

    class Ecs < Platform
    end

    class Fly < Platform
    end

    class Railway < Platform
    end

    # User-provided container id via JUDOSCALE_CONTAINER.
    class Custom < Platform
    end

    # Unsupported or undetected platform.
    class Unknown < Platform
    end
  end
end
