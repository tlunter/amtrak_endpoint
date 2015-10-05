module AmtrakEndpoint
  class Device
    include Redis::Objects

    def self.android_alert(ids, payload)
      ids = [*ids]

      AmtrakEndpoint.gcm.send(
        ids,
        data: { timing_alert: payload },
        collapse_key: 'timing_alert'
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
