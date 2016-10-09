FROM node:5
ADD ./docker-npm-install.sh /docker-npm-install.sh

ADD ./sources.list /etc/apt/sources.list
WORKDIR /opt

RUN git clone https://github.com/wikimedia/restbase.git . && git checkout v0.14.4 && rm -Rfv .git/

RUN /docker-npm-install.sh

EXPOSE 7231

RUN mkdir /db
RUN chmod 777 /db

ADD ./wikitolearn.yaml /opt/projects/




ADD ./kickstart.sh /
RUN chmod +x /kickstart.sh
CMD /kickstart.sh


ADD restbase.patch /tmp/
RUN sha256sum v1/mathoid.yaml && git apply < /tmp/restbase.patch && sha256sum v1/mathoid.yaml
