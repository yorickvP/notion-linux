FROM node:buster
RUN apt-get update
RUN apt-get install -y p7zip-full fakeroot rpm aptly createrepo
RUN npm install -g firebase-tools
