FROM ubuntu:14.04

# Install system dependencies
RUN apt-get -y update
RUN apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev wget git

# Download ruby 2.1.5
WORKDIR /tmp/
RUN wget -q -O /tmp/ruby-2.1.5.tar.gz http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz
RUN tar xvf ruby-2.1.5.tar.gz

# Install ruby 2.1.5
WORKDIR /tmp/ruby-2.1.5/
RUN ./configure --disable-install-rdoc
RUN make -j 4
RUN make -j 4 install
RUN gem install bundler

# Add tracelytics conf
ADD appneta.list /etc/apt/sources.list.d/appneta.list
ADD tracelytics.conf /etc/tracelytics.conf

# Install Tracelyzer
RUN /bin/sh -c "wget -qO- https://apt.appneta.com/appneta-apt-key.pub | apt-key add -"
RUN apt-get -y update
RUN apt-get -y install liboboe0 liboboe-dev

WORKDIR /
ADD . /opt/tlunter/amtrak_endpoint
RUN groupadd --gid 1000 amtrak
RUN useradd --uid 1000 --gid 1000 --create-home amtrak
RUN chown -R amtrak:amtrak /opt/tlunter/

# Install ruby dependencies
WORKDIR /opt/tlunter/amtrak_endpoint
USER amtrak
RUN bundle config --global jobs 8
RUN bundle install --deployment

COPY nginx.conf /opt/nginx/config/amtrak/nginx.conf

CMD bundle exec unicorn -l 3000
ENV DOCKER true
ENV RACK_ENV production
EXPOSE 3000
VOLUME /opt/tlunter/amtrak_endpoint/public
VOLUME /opt/nginx/config/amtrak
