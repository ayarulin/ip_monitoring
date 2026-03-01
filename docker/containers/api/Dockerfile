FROM ruby:4.0.1-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v "4.0.7" --no-document
RUN bundle install

COPY . .

CMD ["bundle", "exec", "ruby", "lib/applications/api/bin/run"]
