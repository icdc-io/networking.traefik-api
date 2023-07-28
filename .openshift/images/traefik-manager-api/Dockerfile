FROM ruby:latest-bullseye
# bookworm (debian 12) release does not build in Openshift 3.x
# so fix image to bullseye (Debian 11)

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

COPY container-assets/entrypoint.sh /usr/local/bin

#CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
CMD ["bash", "entrypoint.sh"]
