require 'json'

module Lev
  class BackgroundJob
    attr_reader :id, :status, :progress, :errors

    STATE_UNQUEUED = 'unqueued'
    STATE_QUEUED = 'queued'
    STATE_WORKING = 'working'
    STATE_SUCCEEDED = 'succeeded'
    STATE_FAILED = 'failed'
    STATE_KILLED = 'killed'
    STATE_UNKNOWN = 'unknown'

    STATES = [
      STATE_UNQUEUED,
      STATE_QUEUED,
      STATE_WORKING,
      STATE_SUCCEEDED,
      STATE_FAILED,
      STATE_KILLED,
      STATE_UNKNOWN
    ].freeze

    def self.create
      new(status: STATE_UNQUEUED).tap do |job|
        job.save_standard_values
      end
    end

    # Finds the job with the specified ID and returns it.  If no such ID
    # exists in the store, returns a job with 'unknown' status and sets it
    # in the store
    def self.find!(id)
      find(id) || new({id: id}).tap do |job|
        job.save_standard_values
      end
    end

    # Finds the job with the specified ID and returns it.  If no such ID
    # exists in the store, returns nil.
    def self.find(id)
      raise(ArgumentError, "`id` cannot be nil") if id.nil?

      attrs = { id: id }

      existing_job_attrs = fetch_and_parse(job_key(id))

      if existing_job_attrs.present?
        attrs.merge!(existing_job_attrs)
        new(attrs)
      else
        nil
      end
    end

    def self.all
      job_ids.map { |id| find!(id) }
    end

    def set_progress(at, out_of = nil)
      progress = compute_fractional_progress(at, out_of)
      set(progress: progress)
    end

    STATES.each do |state|
      define_method("#{state}!") do
        set(status: state)
      end

      define_method("#{state}?") do
        status == state
      end
    end

    (STATES + %w(completed incomplete)).each do |state|
      define_singleton_method("#{state}") do
        all.select{|job| job.send("#{state}?")}
      end
    end

    def completed?
      failed? || succeeded?
    end

    def incomplete?
      !completed?
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
      get_dynamic_variable(method_name) || super
    end

    def respond_to?(method_name)
      has_dynamic_variable?(method_name) || super
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
      apply_consistency_rules!(incoming_hash)
      new_hash = stored.merge(incoming_hash)
      new_hash.each { |k, v| instance_variable_set("@#{k}", v) }
      self.class.store.write(job_key, new_hash.to_json)
      track_job_id
    end

    def apply_consistency_rules!(hash)
      hash.stringify_keys!
      hash['progress'] = 1.0 if hash['status'] == 'succeeded'
    end

    def get_dynamic_variable(name)
      return nil if !has_dynamic_variable?(name)
      instance_variable_get("@#{name}")
    end

    def has_dynamic_variable?(name)
      !name.match(/\?|\!/) && instance_variable_defined?("@#{name}")
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

