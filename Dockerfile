FROM node:5
ADD ./sources.list /etc/apt/sources.list
RUN git clone https://github.com/wikimedia/restbase.git && cd restbase && git checkout v0.14.0 && rm -Rfv .git/

WORKDIR restbase

RUN npm install

EXPOSE 7231

RUN mkdir /db
RUN chmod 777 /db

ADD ./config.yaml /restbase/
ADD ./wikitolearn.yaml /restbase/projects/



ADD ./kickstart.sh /
RUN chmod +x /kickstart.sh
CMD /kickstart.sh


ADD restbase.patch /tmp/
RUN sha256sum v1/mathoid.yaml && git apply < /tmp/restbase.patch && sha256sum v1/mathoid.yaml
