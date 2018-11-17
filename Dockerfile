FROM node:8
ADD ./docker-npm-install.sh /docker-npm-install.sh


RUN cd /opt/ && git clone https://github.com/wikimedia/restbase.git && cd restbase && git checkout v0.18.1 && rm -Rf .git/

WORKDIR /opt/restbase

RUN /docker-npm-install.sh

EXPOSE 7231

RUN mkdir /db
RUN chmod 777 /db

ADD ./wikitolearn.yaml /opt/restbase/projects/

ADD ./kickstart.sh /
RUN chmod +x /kickstart.sh
CMD /kickstart.sh
