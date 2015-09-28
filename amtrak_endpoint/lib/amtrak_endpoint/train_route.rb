module AmtrakEndpoint
  class TrainRoute
    include Redis::Objects

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
      date_obj = Time.parse(date) unless date.nil? || date.strip.empty?
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

    def alert_if_late_departure
      train_times     = get_latest_times(5)
      times_by_number = train_times_by_number(train_times)
      late_trains     = find_late_train_departures(times_by_number)

      unless late_trains.empty?
        ids = devices.map(&Device.method(:new))
          .select { |d| d.type == 'android' }
          .map(&:uuid)
          .tap { |i| AmtrakEndpoint.logger.debug("Alerting devices: #{i}") }
        Device.android_alert(ids, late_trains)
      end
    end

    def scheduled_versus_estimated(times)
      estimated_time = times[:estimated_time].to_s.gsub(/\u0000-\u001F/, '').strip
      scheduled_time = times[:scheduled_time].to_s.gsub(/\u0000-\u001F/, '').strip

      return if estimated_time.empty? || scheduled_time.empty?

      Time.parse(estimated_time) - Time.parse(scheduled_time)
    end

    def find_late_train_departures(times_by_number)
      times_by_number
        .select { |_, all_times| all_times.length > 1 }
        .map { |number, all_times| [number, all_times.map { |t| t[:departure] }] }
        .select { |_, departure_times| departure_times.group_by { |t| t[:date] }.length == 1 }
        .select do |_, departure_times|
          departure_times.all? do |departure_time|
            (diff = scheduled_versus_estimated(departure_time)) && diff > (5 * 60)
          end
        end
        .map(&:first)
        .tap { |t| AmtrakEndpoint.logger.debug("Late trains: #{t}") }
    end

    def train_times_by_number(train_times)
      train_times
        .flatten
        .group_by { |t| t[:number] }
        .tap { |t| AmtrakEndpoint.logger.debug("Train times by train number: #{t}") }
    end

    def used?
      lr = last_request.get
      AmtrakEndpoint.logger.debug "Last Request: #{lr}"
      lr.to_time > (Time.now - 10 * 60 * 60)
    end

    def delete
      redis.multi do |multi|
        devices.del
        cache_times.del
        train_times.del
        last_request.del
      end
    end

    set :devices
    list :cache_times, maxlength: 20
    hash_key :train_times, marshal: true
    value :last_request, marshal: true, default: Time.new
  end
end
