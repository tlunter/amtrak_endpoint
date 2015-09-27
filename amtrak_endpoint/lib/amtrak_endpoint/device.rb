module AmtrakEndpoint
  class Device
    include Redis::Objects

    def self.android_alert(ids, late_trains)
      ids = [*ids]

      AmtrakEndpoint.gcm.send(
        ids,
        data: { late_trains: late_trains },
        collapse_key: 'late_trains'
      ) unless ids.empty?
    end

    attr_reader :uuid

    def initialize(uuid)
      @uuid = uuid
    end

    def id
      uuid
    end

    value :type
    value :type_params, marshal: true
  end
end
