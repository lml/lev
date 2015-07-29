require 'json'

module Lev
  class Status
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
      attrs.each do |k, v|
        instance_variable_set("@#{k}", v)
      end

      @uuid ||= SecureRandom.uuid

      save
    end

    def self.find(uuid)
      attrs = { uuid: uuid }

      if status = store.fetch(status_key(uuid))
        attrs.merge!(JSON.parse(status))
      else
        attrs.merge!(state: STATE_UNKNOWN)
      end

      new(attrs)
    end

    def id
      @uuid
    end

    def status
      @state
    end

    def progress
      @progress ||= set_progress(0)
    end

    def self.all
      job_ids.map { |id| find(id) }
    end

    def set_progress(at, out_of = nil)
      progress = compute_fractional_progress(at, out_of)

      data_to_set = { progress: progress }
      data_to_set[:state] = STATE_COMPLETED if 1.0 == progress

      set(data_to_set)

      progress
    end

    STATES.each do |state|
      define_method("#{state}!") do
        set(state: state)
      end
    end

    def save(hash = {})
      if has_reserved_keys?(hash)
        raise IllegalArgument,
              "Caller cannot specify any reserved keys (#{RESERVED_KEYS})"
      else
        set(hash)
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

    def as_json(options = {})
      json = { id: id, status: status, progress: progress }
      [options[:with]].flatten.each { |w| json[w] = send(w) }
      json
    end

    def method_missing(method_name, *args)
      instance_variable_get("@#{method_name}")
    end

    protected
    RESERVED_KEYS = [:progress, :uuid, :state, :errors]

    def self.store
      # Nice to get the store from lev config each time so it isn't serialized
      # when activejobs are sent off to places like redis
      Lev.configuration.status_store
    end

    def self.job_ids
      store.fetch(status_key('lev_status_uuids')) || []
    end

    def set(incoming_hash)
      if existing_settings.keys.any?
        incoming_hash = existing_settings.merge(incoming_hash)
      end

      incoming_hash.each do |k, v|
        instance_variable_set("@#{k}", v)
      end

      self.class.store.write(status_key, incoming_hash.to_json)
      track_job_id
    end

    def existing_settings
      if status = self.class.store.fetch(status_key)
        JSON.parse(status)
      else
        {}
      end
    end

    def track_job_id
      ids = self.class.job_ids
      ids << @uuid
      self.class.store.write(self.class.status_key('lev_status_uuids'), ids.uniq)
    end

    def status_key
      self.class.status_key(@uuid)
    end

    def self.status_key(uuid)
      "#{Lev.configuration.status_store_namespace}:#{uuid}"
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

