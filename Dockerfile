FROM node:5
RUN git clone https://github.com/wikimedia/restbase.git && cd restbase && git checkout v0.12.1 && rm -Rfv .git/

WORKDIR restbase

RUN npm install

EXPOSE 7231

RUN mkdir /db
RUN chmod 777 /db

ADD ./config.yaml /restbase/

ADD ./kickstart.sh /
RUN chmod +x /kickstart.sh
CMD /kickstart.sh
