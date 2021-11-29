########################
#     Build stage      #
########################
FROM ruby:latest

LABEL AUTHOR, tmatlash@ibagroup.eu

ARG GIT_AUTH
ARG RAILS_ENV
ARG BUILD_BRANCH

RUN apt update -y && \
    apt install -y vim git

RUN git clone -b ${BUILD_BRANCH} https://${GIT_AUTH}/icdc/networking/traefik-manager-api.git /usr/src/app

WORKDIR /usr/src/app
RUN git log -n 1
RUN RAILS_ENV=${RAILS_ENV} bundle update
RUN RAILS_ENV=${RAILS_ENV} bundle install
RUN chgrp -R 0  /usr/src/app && chmod -R g+rwX /usr/src/app
EXPOSE 3000
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]

#########################
#       Run stage       #
#########################
from httpd:2.4

RUN mkdir /usr/local/apache2/conf.d

COPY ./certificates.conf /usr/local/apache2/conf.d/certificates.conf

RUN  echo "Include conf.d/*.conf" >> /usr/local/apache2/conf/httpd.conf

EXPOSE 8080
