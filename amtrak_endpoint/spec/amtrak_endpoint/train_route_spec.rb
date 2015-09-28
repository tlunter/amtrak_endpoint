require 'spec_helper'

describe AmtrakEndpoint::TrainRoute do
  let(:options) { {} }
  subject { described_class.new(from: 'pvd', to: 'bby', **options) }

  describe '.prepare' do
    let(:identifier) { "pvd\36bby" }
    it 'makes a TrainRoute' do
      expect(described_class).to receive(:new)
        .with(from: 'pvd', to: 'bby', date: nil)

      described_class.prepare(identifier)
    end
  end

  describe '#get_time_data' do
    it 'returns train times' do
      expect(Amtrak).to receive(:get)
        .with('pvd', 'bby', date: nil)

      subject.get_time_data
    end

    context 'with a date string set' do
      let(:options) { { date: '2015-01-01T10:01:20Z' } }

      it 'tries to get train times for a date' do
        expect(Amtrak).to receive(:get)
          .with('pvd', 'bby', date: DateTime.new(2015, 1, 1, 10, 1, 20))

        subject.get_time_data
      end
    end
  end

  describe '#cache_train_times' do
    let(:amtrak_data) do
      [
        {
          number: 174,
          departure: {
            date: "Fri, Sep 25 2015",
            scheduled_time: "6:56 am",
            estimated_time: "6:57 am"
          },
          arrival: {
            date: "Fri, Sep 25 2015",
            scheduled_time: "7:53 am",
            estimated_time: "7:46 am"
          },
        },
        {
          number: 86,
          departure: {
            date: "Fri, Sep 25 2015",
            scheduled_time: "6:56 am",
            estimated_time: ""
          },
          arrival: {
            date: "Fri, Sep 25 2015",
            scheduled_time: "7:53 am",
            estimated_time: "7:46 am"
          },
        },
        {
          number: 88,
          departure: {
            date: "Fri, Sep 25 2015",
            scheduled_time: "6:56 am",
            estimated_time: "8:42 am"
          },
          arrival: {
            date: "Fri, Sep 25 2015",
            scheduled_time: "7:53 am",
            estimated_time: ""
          },
        },
      ]
    end

    it 'keeps a history of train times' do
      expect(Amtrak).to receive(:get)
        .with('pvd', 'bby', date: nil)
        .and_return(amtrak_data)

      subject.cache_train_times

      expect(subject.cache_times).to_not be_empty
      expect(subject.train_times[subject.cache_times.first]).to eq(amtrak_data)
    end
  end

  describe '#clean_old_train_times' do
    it 'removes keys in train_times not found in current_times' do
      (0..20).each do |i|
        time = DateTime.new(2015, 1, 1, 1, 1, i).iso8601
        subject.train_times[time] = nil
        subject.cache_times.unshift(time)
      end

      expect(subject.cache_times.length).to eq(20)
      expect(subject.train_times.keys - subject.cache_times.values).to_not be_empty

      expect(subject.clean_old_train_times(subject.cache_times.values)).to eq(1)

      expect(subject.train_times.keys.sort.reverse).to eq(subject.cache_times.values)
    end
  end

  describe '#get_latest_times' do
    before do
      (0...20).each do |i|
        time = DateTime.new(2015, 1, 1, 1, 1, i).iso8601
        subject.train_times[time] = nil
        subject.cache_times.unshift(time)
      end
    end

    context 'with no arguments' do
      it 'returns a list of one' do
        expect(subject.get_latest_times.length).to eq(1)
      end
    end

    context 'with an argument greater than 1' do
      it 'returns a list of two' do
        expect(subject.get_latest_times(2).length).to eq(2)
      end
    end

    context 'with an argument equal to 0' do
      it 'returns a list of two' do
        expect(subject.get_latest_times(0).length).to eq(0)
      end
    end
  end

  describe '#train_times_by_number' do
    let(:train_times) do
      [
        [
          {
            number: 174,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:56 am",
              estimated_time: "6:57 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:53 am",
              estimated_time: "7:46 am"
            },
          },
          {
            number: 176,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "10:56 am",
              estimated_time: "10:57 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "11:53 am",
              estimated_time: "11:46 am"
            },
          },
        ],
        [
          {
            number: 174,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:57 am",
              estimated_time: "6:58 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:54 am",
              estimated_time: "7:47 am"
            },
          },
        ],
      ]
    end
    let(:output) do
      {
        174 => [
          {
            number: 174,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:56 am",
              estimated_time: "6:57 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:53 am",
              estimated_time: "7:46 am"
            },
          },
          {
            number: 174,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:57 am",
              estimated_time: "6:58 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:54 am",
              estimated_time: "7:47 am"
            },
          },
        ],
        176 => [
          {
            number: 176,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "10:56 am",
              estimated_time: "10:57 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "11:53 am",
              estimated_time: "11:46 am"
            },
          },
        ],
      }
    end

    it 'reformats to hash by train number' do
      expect(subject.train_times_by_number(train_times)).to eq(output)
    end
  end

  describe '#scheduled_versus_estimated' do
    context 'with both times' do
      let(:train_time) do
        {
          date: "Fri, Sep 25 2015",
          scheduled_time: "6:56 am",
          estimated_time: "6:57 am"
        }
      end

      it 'returns the minute difference' do
        expect(subject.scheduled_versus_estimated(train_time))
          .to eq(60)
      end
    end

    context 'with only scheduled time' do
      context 'with an empty estimated_time' do
        let(:train_time) do
          {
            date: "Fri, Sep 25 2015",
            scheduled_time: "6:56 am",
            estimated_time: ""
          }
        end

        it 'returns the minute difference' do
          expect(subject.scheduled_versus_estimated(train_time))
            .to be_nil
        end
      end

      context 'with a new line in estimated_time' do
        let(:train_time) do
          {
            date: "Fri, Sep 25 2015",
            scheduled_time: "6:56 am",
            estimated_time: "\n"
          }
        end

        it 'returns the minute difference' do
          expect(subject.scheduled_versus_estimated(train_time))
            .to be_nil
        end
      end
    end
  end

  describe '#find_late_train_departures' do
    let(:train_times_by_number) do
      {
        174 => [
          {
            number: 174,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:36 am",
              estimated_time: "6:57 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:53 am",
              estimated_time: "7:46 am"
            },
          },
          {
            number: 174,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:57 am",
              estimated_time: "6:58 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:54 am",
              estimated_time: "7:47 am"
            },
          },
        ],
        179 => [
          {
            number: 179,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:36 am",
              estimated_time: "6:57 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:53 am",
              estimated_time: "7:46 am"
            },
          },
          {
            number: 179,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:36 am",
              estimated_time: "6:58 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:54 am",
              estimated_time: "7:47 am"
            },
          },
        ],
        175 => [
          {
            number: 175,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:56 am",
              estimated_time: "6:57 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:53 am",
              estimated_time: "7:46 am"
            },
          },
          {
            number: 175,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "6:57 am",
              estimated_time: ""
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "7:54 am",
              estimated_time: "7:47 am"
            },
          },
        ],
        176 => [
          {
            number: 176,
            departure: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "10:56 am",
              estimated_time: "10:57 am"
            },
            arrival: {
              date: "Fri, Sep 25 2015",
              scheduled_time: "11:53 am",
              estimated_time: "11:46 am"
            },
          },
        ],
        178 => [
        ],
      }
    end
    let(:output) { [179] }

    it 'finds only those trains that are more than once late by five minutes' do
      expect(subject.find_late_train_departures(train_times_by_number))
        .to eq(output)
    end
  end
end
