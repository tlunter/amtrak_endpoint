module AmtrakEndpoint
  class Device
    include Redis::Objects

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
