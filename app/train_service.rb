require 'excon'
require 'date'

# Service for getting train time HTML page from the Amtrak website
class TrainService
  def self.get(*args)
    new(*args).get
  end

  attr_reader :from, :to

  def initialize(from, to, date: nil)
    @from = from
    @to = to
    @date = date
  end

  def get
    Excon.post(
      'http://tickets.amtrak.com/itd/amtrak',
      headers: headers,
      body: URI.encode_www_form(body)
    )
  end

  def headers
    { 'Content-Type' => 'application/x-www-form-urlencoded' }
  end

  # rubocop:disable all
  def body
    {
      "_handler=amtrak.presentation.handler.request.rail.AmtrakRailTrainStatusSearchRequestHandler/_xpath=/sessionWorkflow/productWorkflow[@product='Rail']" => '',
      "/sessionWorkflow/productWorkflow[@product='Rail']/tripRequirements/journeyRequirements[1]/departDate.date" => departure_date,
      'requestor'        => 'amtrak.presentation.handler.page.rail.AmtrakRailGetTrainStatusPageHandler',
      'xwdf_trainNumber' => "/sessionWorkflow/productWorkflow[@product='Rail']/tripRequirements/journeyRequirements[1]/segmentRequirements[1]/serviceCode",
      'wdf_trainNumber'  => 'optional',
      'xwdf_SortBy'      => "/sessionWorkflow/productWorkflow[@product='Rail']/tripRequirements/journeyRequirements[1]/departDate/@radioSelect",
      'wdf_SortBy'       => 'arrivalTime',
      'xwdf_origin'      => "/sessionWorkflow/productWorkflow[@product='Rail']/travelSelection/journeySelection[1]/departLocation/search",
      'wdf_origin'       => from.to_s,
      'xwdf_destination' => "/sessionWorkflow/productWorkflow[@product='Rail']/travelSelection/journeySelection[1]/arriveLocation/search",
      'wdf_destination'  => to.to_s,
    }
  end
  # rubocop:enable all

  def departure_date
    date.strftime('%a, %b %-d, %Y')
  end

  def date
    @date ||= Date.today
  end
end