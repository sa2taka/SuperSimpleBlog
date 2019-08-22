FROM ruby:2.6.2

ENV APP_ROOT /usr/src/super-simple-blog

WORKDIR $APP_ROOT

RUN apt-get update && \
    apt-get install -y sqlite3 gconf-service libasound2 libatk1.0-0 libcairo2 libcups2 libfontconfig1 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libxss1 fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils && \
     wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
     dpkg -i google-chrome-stable_current_amd64.deb; \
     apt -f install -y

COPY . $APP_ROOT
WORKDIR $APP_ROOT

RUN bundle install && \
  sqlite3 data.db < create_database.sqlite3

ENV APP_ENV production
EXPOSE  9292
CMD ["rackup", "-o", "0.0.0.0", "-p", "9292"]
