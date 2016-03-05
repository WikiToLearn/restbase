FROM node:5
RUN git clone https://github.com/wikimedia/restbase.git && cd restbase && git checkout v0.11.3 && rm -Rfv .git/
WORKDIR restbase
RUN npm install
RUN cp config.example.yaml config.yaml
CMD node server
