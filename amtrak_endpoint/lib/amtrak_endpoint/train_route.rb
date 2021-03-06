module AmtrakEndpoint
  class TrainRoute
    include Redis::Objects

    MAX_TIMES = 20

    def self.prepare(identifier)
      from, to, date = identifier.split("\36")
      new(from: from, to: to, date: date)
    end

    attr_reader :from, :to, :date

    def initialize(from: nil, to: nil, date: nil)
      @from = from
      @to = to
      @date = date
    end

    def id
      [from, to, date].join("\36")
    end

    def get_time_data
      report = { from: from, to: to, date: date }
      if date.nil? || date.strip.empty?
        date_obj = Time.now.in_time_zone('Pacific Time (US & Canada)').to_date
      else
        date_obj = Time.parse(date)
      end
      if TraceView.tracing?
        AmtrakEndpoint.logger.debug('Tracing amtrak data')
        TraceView::API.trace('amtrak', report) do
          Amtrak.get(from, to, date: date_obj)
        end
      else
        AmtrakEndpoint.logger.debug('Not tracing amtrak data')
        Amtrak.get(from, to, date: date_obj)
      end
    end

    def clean_old_train_times(current_times)
      old_times = train_times.keys
      AmtrakEndpoint.logger.debug "Current Times: #{current_times}"
      AmtrakEndpoint.logger.debug "Old Times: #{old_times}"
      missing_times = old_times - current_times
      AmtrakEndpoint.logger.info "Clearing out: `#{missing_times}`"
      train_times.delete(*missing_times) unless missing_times.empty?
    end

    def cache_train_times
      key = Time.now.iso8601
      data = get_time_data
      AmtrakEndpoint.logger.info "Returned data: #{data}"
      train_times[key] = data
      cache_times.unshift(key)

      clean_old_train_times(cache_times.values)

      data
    end

    def get_latest_times(number=1)
      return [] if number < 1

      cache_times[0...number].map(&train_times.method(:[]))
    end

    def used?
      lr = last_request.get
      AmtrakEndpoint.logger.debug "Last Request: #{lr}"
      lr.to_time > (Time.now - 10 * 60 * 60)
    end

    def delete
      redis.multi do |multi|
        cache_times.del
        train_times.del
        last_request.del
      end
    end

    list :cache_times, maxlength: MAX_TIMES
    hash_key :train_times, marshal: true
    value :last_request, marshal: true, default: Time.new
  end
end
