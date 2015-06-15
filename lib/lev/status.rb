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

    attr_reader :uuid

    def initialize(uuid = nil)
      @uuid = uuid || SecureRandom.uuid
    end

    def self.find(uuid)
      store.fetch(status_key(uuid))
    end

    def set_progress(at, out_of = nil)
      prevent_faulty_arguments(at, out_of)

      if set_status_progress(at, out_of) == 1.0
        set(status: STATUS_COMPLETED)
      end
    end

    STATUSES.each do |status|
      define_method("#{status}!") do
        set(status: status)
      end
    end

    def save(hash)
      if has_reserved_keys?(hash)
        raise IllegalArgument,
              "Caller cannot specify any reserved keys (#{RESERVED_KEYS})"
      else
        set(hash)
      end
    end

    def add_error(error, options = { })
      options = { is_fatal: false }.merge(options)
      push('errors', { is_fatal: options[:is_fatal],
                       code: error.code,
                       message: error.message })
    end

    def get(key)
      if value = self.class.store.fetch(status_key)
        decoded_hash = JSON.parse(value)
        decoded_hash.merge(uuid: uuid)[key]
      else
        false
      end
    end

    protected
    RESERVED_KEYS = [:progress, :uuid, :status, :errors]

    def self.store
      # Nice to get the store from lev config each time so it isn't serialized
      # when activejobs are sent off to places like redis
      Lev.configuration.status_store
    end

    def set(incoming_hash)
      self.class.store.write(status_key, incoming_hash.to_json)
    end

    def status_key
      "#{Lev.configuration.status_store_namespace}:#{uuid}"
    end

    def self.status_key(uuid)
      "#{Lev.configuration.status_store_namespace}:#{uuid}"
    end

    def has_reserved_keys?(hash)
      (hash.keys.collect(&:to_sym) & RESERVED_KEYS).any?
    end

    def push(key, new_item)
      new_value = (get(key) || []).push(new_item)
      set(key => new_value)
    end

    STATUSES.each do |status|
      define_method("#{status}?") do
        get('status') == status
      end
    end

    def set_status_progress(at, out_of)
      if out_of.nil? && (at < 0 || at > 1)
        raise IllegalArgument,
              "If `out_of` not specified, `at` must be in the range [0.0, 1.0]"
      elsif out_of.nil?
        set(progress: at)
      else
        set(progress: (at.to_f / out_of.to_f))
      end
    end

    def prevent_faulty_arguments(at, out_of)
      if at.nil?
        raise IllegalArgument, "Must specify at least `at` argument to `progress` call"
      elsif at < 0
        raise IllegalArgument, "progress cannot be negative (at=#{at})"
      elsif out_of && out_of < at
        raise IllegalArgument, "`out_of` must be greater than `at` in `progress` calls"
      end
    end

  end
end

