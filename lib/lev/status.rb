require 'json'

module Lev
  class Status

    STATUS_QUEUED = 'queued'
    STATUS_WORKING = 'working'
    STATUS_COMPLETED = 'completed'
    STATUS_FAILED = 'failed'
    STATUS_KILLED = 'killed'
    STATUSES = [
      STATUS_QUEUED,
      STATUS_WORKING,
      STATUS_COMPLETED,
      STATUS_FAILED,
      STATUS_KILLED
    ].freeze

    def self.get(uuid)
      decoded_hash = decode(self.store.fetch(status_key(uuid)))
      decoded_hash.merge(uuid: uuid)
    end

    attr_reader :uuid

    def initialize
      @uuid = SecureRandom.uuid()
    end

    def set_progress(at, out_of = nil)
      raise IllegalArgument, "Must specify at least `at` argument to `progress` call" if at.nil?
      raise IllegalArgument, "progress cannot be negative (at=#{at})" if at < 0
      raise IllegalArgument, "`out_of` must be greater than `at` in `progress` calls" unless out_of > at

      progress =
        if out_of.nil?
          raise IllegalArgument, "If `out_of` not specified, `at` must be in the range [0.0,1.0]" \
            if at < 0 || at > 1
          set(progress: at)
        else
          set(progress: (at.to_f / out_of.to_f))
        end

      data_to_set = { progress: progress }
      data_to_set[:status] = STATUS_COMPLETED if progress == 1.0

      set(data_to_set)
    end

    def progress
      get('progress')
    end

    STATUSES.each do |status|
      define_method("#{status}?") do
        get('status') === status
      end

      define_method("#{status}!") do
        set('status', status)
      end
    end

    def save(hash)
      raise IllegalArgument, "Caller cannot specify any reserved keys (#{RESERVED_KEYS})" \
        if has_reserved_keys?(hash)

      set(hash)
    end

    def add_error(is_fatal, error)
      push('errors', {
        is_fatal: is_fatal,
        code: error.code,
        message: error.message
      })
    end

    def errors
      get('errors') || []
    end

    protected

    RESERVED_KEYS = [:progress, :uuid, :status, :errors]

    def self.store
      # Nice to get the store from lev config each time so it isn't serialized
      # when activejobs are sent off to places like redis
      Lev.configuration.status_store
    end

    def set(incoming_hash)
      decoded_hash = self.get(uuid)
      decoded_hash.merge(incoming_hash)
      self.store.write(status_key(uuid), encode(decoded_hash))
    end

    def get(key)
      self.get(uuid)[key]
    end

    def encode(val)
      val.to_json
    end

    def decode(val)
      JSON.parse(val)
    end

    def status_key(uuid)
      "status:#{uuid}" # TODO make this namespace configurable
    end

    def has_reserved_keys?(hash)
      (hash.keys.collect{|key| key.to_sym} & RESERVED_KEYS).any?
    end

    def push(key, new_item)
      new_value = (get(key) || []).push(new_item)
      set(key: new_value)
    end

  end
end

