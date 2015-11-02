require 'json'

module Lev
  class BackgroundJob
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

    def self.create
      new(status: STATE_UNKNOWN).tap do |job|
        job.save_standard_values
      end
    end

    def self.find(id)
      raise(ArgumentError, "`id` cannot be nil") if id.nil?

      attrs = { id: id }

      existing_job_attrs = fetch_and_parse(job_key(id))

      if existing_job_attrs.present?
        attrs.merge!(existing_job_attrs)
        new(attrs)
      else
        new(attrs).tap do |job|
          job.save_standard_values
        end
      end
    end

    def self.all
      job_ids.map { |id| find(id) }
    end

    def self.incomplete
      all.select { |j| !j.completed? }
    end

    def self.queued
      all.select(&:queued?)
    end

    def self.working
      all.select(&:working?)
    end

    def self.failed
      all.select(&:failed?)
    end

    def self.killed
      all.select(&:killed?)
    end

    def self.unknown
      all.select(&:unknown?)
    end

    def self.complete
      all.select(&:completed?)
    end

    def set_progress(at, out_of = nil)
      progress = compute_fractional_progress(at, out_of)

      data_to_set = { progress: progress }
      data_to_set[:status] = STATE_COMPLETED if 1.0 == progress

      set(data_to_set)

      progress
    end

    (STATES - [STATE_COMPLETED]).each do |state|
      define_method("#{state}!") do
        set(status: state)
      end
    end

    STATES.each do |state|
      define_method("#{state}?") do
        status == state
      end
    end

    def completed!
      set({status: STATE_COMPLETED, progress: 1.0})
    end

    def add_error(error, options = { })
      options = { is_fatal: false }.merge(options)
      @errors << { is_fatal: options[:is_fatal],
                   code: error.code,
                   message: error.message,
                   data: error.data }
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

    def save_standard_values
      set({
        id: id,
        status: status,
        progress: progress,
        errors: errors
      })
    end

    def method_missing(method_name, *args)
      method_name = method_name.to_s.sub(/\?/, '')
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

    def initialize(attrs = {})
      attrs = attrs.stringify_keys

      @id = attrs['id'] || SecureRandom.uuid
      @status = attrs['status'] || STATE_UNKNOWN
      @progress = attrs['progress'] || 0
      @errors = attrs['errors'] || []
    end

    def set(incoming_hash)
      incoming_hash = incoming_hash.stringify_keys
      incoming_hash = stored.merge(incoming_hash)
      incoming_hash.each { |k, v| instance_variable_set("@#{k}", v) }
      self.class.store.write(job_key, incoming_hash.to_json)
      track_job_id
    end

    def self.store
      Lev.configuration.job_store
    end

    def self.fetch_and_parse(job_key)
      fetched = store.fetch(job_key)
      return nil if fetched.nil?
      JSON.parse(fetched).stringify_keys!
    end

    def self.job_ids
      store.fetch(job_key('lev_job_ids')) || []
    end

    def stored
      self.class.fetch_and_parse(job_key) || {}
    end

    def track_job_id
      ids = self.class.job_ids
      return if ids.include?(@id)
      ids << @id
      self.class.store.write(self.class.job_key('lev_job_ids'), ids)
    end

    def job_key
      self.class.job_key(@id)
    end

    def self.job_key(id)
      "#{Lev.configuration.job_store_namespace}:#{id}"
    end

    def has_reserved_keys?(hash)
      (hash.keys.collect(&:to_sym) & RESERVED_KEYS).any?
    end

    def push(key, new_item)
      new_value = (send(key) || []).push(new_item)
      set(key => new_value)
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

