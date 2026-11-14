# frozen_string_literal: true

module RecordingStudioSitemaps
  # Ordered name → block list for sources or filters.
  # Registering a name that is already present replaces that block and keeps its place.
  class Registry
    Registration = Struct.new(:name, :block, keyword_init: true)

    def initialize
      @registrations = []
    end

    def register(name, &block)
      key = normalize_name(name)
      raise ArgumentError, "Pass a block" unless block

      found = find(key)
      if found
        found.block = block
      else
        @registrations << Registration.new(name: key, block: block)
      end
      key
    end

    def unregister(name)
      key = normalize_name(name)
      @registrations.reject! { |registration| registration.name == key }
      key
    end

    def names
      @registrations.map(&:name)
    end

    def each(&)
      @registrations.each(&)
    end

    def snapshot
      @registrations.map { |registration| [registration.name, registration.block] }
    end

    def restore(snapshot)
      @registrations = Array(snapshot).map do |name, block|
        Registration.new(name: name, block: block)
      end
    end

    private

    def find(name)
      @registrations.find { |registration| registration.name == name }
    end

    def normalize_name(name)
      raise ArgumentError, "Name can't be blank" if name.nil? || name.to_s.strip.empty?

      name.to_sym
    end
  end
end
