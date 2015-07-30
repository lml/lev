require 'json'

module Lev
  class Status
    attr_reader :id, :status, :progress, :errors

    STATE_QUEUED = 'queued'
    STATE_WORKING = 'working'
    STATE_COMPLETED = 'completed'
    STATE_FAILED = 'failed'
    STATE_KILLED = 'killed'
    STATE_UNKNOWN = 'unknown'

    STATES = [
      STATE_QUEUED,
      STATE_WORKING,
      STATE_COMPLETED,
      STATE_FAILED,
      STATE_KILLED,
      STATE_UNKNOWN
    ].freeze

    def initialize(attrs = {})
      @id = attrs[:id] || attrs['id'] || SecureRandom.uuid
      @status = attrs[:status] || attrs['status'] || STATE_UNKNOWN
      @progress = attrs[:progress] || attrs['progress'] || set_progress(0)
      @errors = attrs[:errors] || attrs['errors'] || []

      set({ id: id,
            status: status,
            progress: progress,
            errors: errors })
    end

    def self.find(id)
      attrs = { id: id }

      if status = store.fetch(status_key(id))
        attrs.merge!(JSON.parse(status))
      else
        attrs.merge!(status: STATE_UNKNOWN)
      end

      new(attrs)
    end

    def self.all
      job_ids.map { |id| find(id) }
    end

    def set_progress(at, out_of = nil)
      progress = compute_fractional_progress(at, out_of)

      data_to_set = { progress: progress }
      data_to_set[:status] = STATE_COMPLETED if 1.0 == progress

      set(data_to_set)

      progress
    end

    STATES.each do |state|
      define_method("#{state}!") do
        set(status: state)
      end
    end

    def add_error(error, options = { })
      @errors ||= []
      options = { is_fatal: false }.merge(options)
      @errors << { is_fatal: options[:is_fatal],
                   code: error.code,
                   message: error.message }
      set(errors: @errors)
    end

    # Rails compatibility
    # returns a Hash of all key-value pairs that have been #set()
    def as_json(options = {})
      stored
    end

    def save(incoming_hash)
      if reserved = incoming_hash.select { |k, _| RESERVED_KEYS.include?(k) }.first
        raise IllegalArgument, "Cannot set reserved key: #{reserved[0]}"
      else
        set(incoming_hash)
      end
    end

    def method_missing(method_name, *args)
      instance_variable_get("@#{method_name}") || super
    end

    def respond_to?(method_name)
      if method_name.match /\?$/
        super
      else
        instance_variable_get("@#{method_name}").present? || super
      end
    end

    protected
    RESERVED_KEYS = [:id, :status, :progress, :errors]

    def set(incoming_hash)
      incoming_hash = stored.merge(incoming_hash)
      incoming_hash.each { |k, v| instance_variable_set("@#{k}", v) }
      self.class.store.write(status_key, incoming_hash.to_json)
      track_job_id
    end

    def self.store
      Lev.configuration.status_store
    end

    def self.job_ids
      store.fetch(status_key('lev_status_ids')) || []
    end

    def stored
      if found = self.class.store.fetch(status_key)
        JSON.parse(found)
      else
        {}
      end
    end

    def track_job_id
      ids = self.class.job_ids
      ids << @id
      self.class.store.write(self.class.status_key('lev_status_ids'), ids.uniq)
    end

    def status_key
      self.class.status_key(@id)
    end

    def self.status_key(id)
      "#{Lev.configuration.status_store_namespace}:#{id}"
    end

    def has_reserved_keys?(hash)
      (hash.keys.collect(&:to_sym) & RESERVED_KEYS).any?
    end

    def push(key, new_item)
      new_value = (send(key) || []).push(new_item)
      set(key => new_value)
    end

    STATES.each do |state|
      define_method("#{state}?") do
        status == state
      end
    end

    def compute_fractional_progress(at, out_of)
      if at.nil?
        raise IllegalArgument, "Must specify at least `at` argument to `progress` call"
      elsif at < 0
        raise IllegalArgument, "progress cannot be negative (at=#{at})"
      elsif out_of && out_of < at
        raise IllegalArgument, "`out_of` must be greater than `at` in `progress` calls"
      elsif out_of.nil? && (at < 0 || at > 1)
        raise IllegalArgument, "If `out_of` not specified, `at` must be in the range [0.0, 1.0]"
      end

      at.to_f / (out_of || 1).to_f
    end

  end
end

