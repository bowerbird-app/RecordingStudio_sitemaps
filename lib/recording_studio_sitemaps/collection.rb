# frozen_string_literal: true

module RecordingStudioSitemaps
  # Walks every source in registration order, in batches, then runs built-in
  # checks and every registered filter. Nothing here is accumulated until a
  # caller asks for the full list. Rebuild streams accepted entries into XML.
  #
  # A later sitemap index can count accepted decisions and open a new urlset
  # at the 50,000 URL cap without asking sources to load every row.
  class Collection
    Decision = Struct.new(:entry, :filter_name, :reason, keyword_init: true) do
      def accepted?
        filter_name.nil?
      end
    end

    class << self
      def each_decision(&)
        new.each_decision(&)
      end

      def decisions
        each_decision.to_a
      end

      def accepted
        each_decision.filter_map { |decision| decision.entry if decision.accepted? }
      end

      def withheld
        each_decision.reject(&:accepted?)
      end
    end

    def each_decision
      return enum_for(:each_decision) unless block_given?

      RecordingStudioSitemaps.sources.each do |registration|
        SourceRunner.new(registration).each_batch do |batch|
          batch.each { |entry| yield decide(entry) }
        end
      end
    end

    private

    def decide(entry)
      check = BuiltinChecks.call(entry)
      return withhold(entry, check.filter_name, check.reason) if check

      RecordingStudioSitemaps.filters.each do |filter|
        decision = apply_filter(filter, entry)
        return decision if decision
      end

      Decision.new(entry: entry)
    end

    def apply_filter(filter, entry)
      result = filter.block.call(entry)
      return if keep?(result)

      withhold(entry, filter.name, reason_for(filter, result))
    rescue StandardError => e
      log_filter_error(filter, entry, e)
      withhold(entry, filter.name, "Filter failed")
    end

    def keep?(result)
      !(result == false || result.nil? || result.is_a?(String))
    end

    def reason_for(filter, result)
      return result if result.is_a?(String) && result.strip != ""

      label_for(filter.name)
    end

    def withhold(entry, filter_name, reason)
      Decision.new(entry: entry, filter_name: filter_name, reason: reason)
    end

    def label_for(name)
      name.to_s.tr("_", " ").capitalize
    end

    def log_filter_error(filter, entry, error)
      Log.error(
        "[recording_studio_sitemaps] filter #{filter.name} dropped #{entry.loc}: " \
        "#{error.class}: #{error.message}"
      )
    end
  end
end
