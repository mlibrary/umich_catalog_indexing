FROM jruby:9.2

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential 

ENV BUNDLE_PATH /gems

RUN mkdir -p /gems 
RUN mkdir /app

WORKDIR /app
