module AmtrakEndpoint
  class TrainRoute
    include Redis::Objects

    attr_reader :from, :to

    def initialize(from: nil, to: nil)
      @from = from
      @to = to
    end

    def id
      [from, to].join(':')
    end

    set :devices
  end
end
