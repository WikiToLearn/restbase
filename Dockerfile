FROM node:5
ADD /src/docker-npm-install.sh /docker-npm-install.sh

RUN git clone https://github.com/wikimedia/restbase.git && cd restbase && git checkout v0.15.2 && rm -Rfv .git/

WORKDIR restbase

RUN /docker-npm-install.sh

EXPOSE 7231

RUN mkdir /db
RUN chmod 777 /db

ADD ./src/restbase/config.yaml /restbase/


ADD ./src/restbase/projects/wikitolearn.yaml /restbase/projects/

ADD ./src/docker-entrypoint.sh /
ENTRYPOINT /docker-entrypoint.sh


ADD restbase.patch /tmp/
RUN sha256sum v1/mathoid.yaml && git apply < /tmp/restbase.patch && sha256sum v1/mathoid.yaml
