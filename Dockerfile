FROM ruby:3.2

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy gemspec and Gemfile
COPY activejob-uniqueness.gemspec Gemfile ./
COPY lib/active_job/uniqueness/version.rb ./lib/active_job/uniqueness/

# Install gems
RUN bundle install

# Copy the rest of the application
COPY . .

# Default command
CMD ["bundle", "exec", "rspec"]
