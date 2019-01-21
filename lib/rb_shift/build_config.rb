# frozen_string_literal: true

require_relative 'openshift_kind'
require_relative 'build'

module RbShift
  # Representation of OpenShift build config
  class BuildConfig < OpenshiftKind
    def builds(update = false)
      bc_label = 'openshift.io/build-config.name'.to_sym
      if update || @_builds.nil?
        items = @parent.client
                  .get('builds', namespace: @parent.name)
                  .select { |item| item[:metadata][:annotations][bc_label] == name }

        @_builds = items.each_with_object({}) do |item, hash|
          resource            = Build.new(self, item)
          hash[resource.name] = resource
        end
      end
      @_builds
    end

    def running?(reload = false)
      builds(true) if reload
      !builds.values.select(&:running?).empty?
    end

    def wait_for_build(timeout: 60, polling: 5)
      Timeout.timeout(timeout) do
        log.info "Waiting for builds of #{name} to be finished for #{timeout} seconds..."
        loop do
          log.debug "--> Checking builds after #{polling} seconds..."
          sleep polling
          break unless running?(true)
        end
      end
      log.info 'Build finished'
    end

    def start_build(block: false, timeout: 60, polling: 5, **opts)
      log.info "Starting build from BuildConfig #{name} with options #{opts}"
      @parent.execute('start-build ', name, **opts)
      sleep polling * 2
      builds(true)
      wait_for_build(timeout: timeout, polling: polling) if block
    end
  end
end
