FROM ubuntu:14.04

# Install system dependencies
RUN apt-get -y update
RUN apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev wget git python

# Download ruby 2.1.5
WORKDIR /tmp/

# Install ruby 2.1.5
RUN wget -q -O /tmp/ruby-2.1.5.tar.gz http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz && \
    tar -xvf ruby-2.1.5.tar.gz         && \
    cd /tmp/ruby-2.1.5/                && \
    ./configure --disable-install-rdoc && \
    make -j 4                          && \
    make -j 4 install                  && \
    cd /                               && \
    rm -rf /tmp/ruby-2.1.5 /tmp/ruby-2.1.5.tar.gz
RUN gem install bundler

RUN wget -q -O /tmp/node-v0.12.7.tar.gz https://nodejs.org/dist/v0.12.7/node-v0.12.7.tar.gz && \
    tar -xvf node-v0.12.7.tar.gz       && \
    cd /tmp/node-v0.12.7/              && \
    ./configure                        && \
    make                               && \
    make install                       && \
    cd /                               && \
    rm -rf /tmp/node-v0.12.7 /tmp/node-v0.12.7.tar.gz

# Add tracelytics conf
ADD appneta.list /etc/apt/sources.list.d/appneta.list
ADD tracelytics.conf /etc/tracelytics.conf

# Install Tracelyzer
RUN /bin/sh -c "wget -qO- https://apt.appneta.com/appneta-apt-key.pub | apt-key add -"
RUN apt-get -y update
RUN apt-get -y install liboboe0 liboboe-dev

RUN groupadd --gid 1000 amtrak
RUN useradd --uid 1000 --gid 1000 --create-home amtrak

USER amtrak
ADD Gemfile /tmp/Gemfile
ADD Gemfile.lock /tmp/Gemfile.lock
RUN bundle config --global jobs 8
RUN bundle install --path ~/.gems

WORKDIR /
USER root
ADD . /opt/tlunter/amtrak_endpoint
RUN chown -R amtrak:amtrak /opt/tlunter/

# Install ruby dependencies
WORKDIR /opt/tlunter/amtrak_endpoint
USER amtrak
RUN bundle install --path ~/.gems
RUN npm install
RUN node_modules/.bin/gulp

ADD nginx.conf /opt/nginx/config/amtrak/nginx.conf

ENTRYPOINT ["bundle", "exec", "rake"]
ENV DOCKER true
ENV RACK_ENV production
ENV ENVIRONMENT production
EXPOSE 3000
VOLUME /opt/tlunter/amtrak_endpoint/public
VOLUME /opt/nginx/config/amtrak
