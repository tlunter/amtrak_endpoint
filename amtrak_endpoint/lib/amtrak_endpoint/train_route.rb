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
      date_obj = DateTime.parse(date) if date
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
      key = DateTime.now.iso8601
      data = get_time_data
      AmtrakEndpoint.logger.info "Returned data: #{data}"
      train_times[key] = data
      cache_times.unshift(key)

      clean_old_train_times(cache_times.values)

      data
    end

    def get_latest_times(number=1)
      cache_times.range(0, number - 1).map do |key|
        train_times[key]
      end
    end

    def alert_if_late_departure
      train_times = get_latest_times(2)
      if train_times.length >= 2
        late_trains = diff_train_departures(train_times).select do |number, diff|
          diff > (10 * 60) / 86400
        end

        unless late_trains.empty?
          ids = devices.map(&Device.method(:new))
            .select { |d| d.type == 'android' }
            .map(&:uuid)
          Device.android_alert(ids, late_trains)
        end
      end
    end

    def diff_train_departures(train_times)
      AmtrakEndpoint.logger.debug("Diffing train times: #{train_times}")
      times_by_number = train_times_by_number(train_times)

      AmtrakEndpoint.logger.debug("Train times by train number: #{times_by_number}")
      times_by_number.each_with_object({}) do |(number, times), hash|
        next if times.empty?

        first_time = time.first
        second_time = time.last

        if first_time[:date] != second_time[:date]
          AmtrakEndpoint.logger.debug("Comparing two times with different dates")
          next
        end

        first_actual_time = resolve_correct_time(first_time)
        second_actual_time = resolve_correct_time(second_time)

        hash[number] = DateTime.parse(first_actual_time) - DateTime.parse(second_actual_time)
      end
    end

    def resolve_correct_time(train_time_by_number)
      if train_time_by_number[:estimated_time].nil? || train_time_by_number[:estimated_time].empty?
        train_time_by_number[:scheduled_time]
      else
        train_time_by_number[:estimated_time]
      end
    end

    def train_times_by_number(train_times)
      number_to_times = Hash.new { |hash, key| hash[key] = [] }

      train_times.each do |train_time|
        train_time.each do |train|
          number_to_times[train[:number]] << train[:departure]
        end
      end

      number_to_times
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
    value :last_request, marshal: true, default: DateTime.new
  end
end
