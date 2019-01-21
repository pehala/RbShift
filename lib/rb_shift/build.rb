# frozen_string_literal: true

require_relative 'openshift_kind'

module RbShift
  # Representation of OpenShift build
  class Build < OpenshiftKind
    def phase
      obj[:status][:phase]
    end

    def running?
      reload
      phase == 'Running' || phase == 'Pending'
    end

    def completed?
      reload
      phase == 'Completed'
    end
  end
end
