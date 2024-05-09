FROM golang:1.18.10-buster AS builder

# Control-plane Supporting Packages
RUN apt-get update
RUN apt-get -y install wget git sudo

# Install WebConsole's dependencies
RUN apt remove cmdtest yarn nodejs
RUN apt-get -y install apt-transport-https
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
RUN apt-get update
RUN apt-get -y install nodejs yarn
RUN corepack enable

# Get Free5GC webconsole source code
WORKDIR $GOPATH/src
RUN git clone --recursive -b v3.3.0 -j `nproc` https://github.com/free5gc/free5gc.git

# Build WebConsole
WORKDIR $GOPATH/src/free5gc
RUN make webconsole

# Build the final image
FROM alpine

WORKDIR /free5gc

COPY --from=builder /go/src/free5gc/webconsole/bin/webconsole ./webconsole/
COPY --from=builder /go/src/free5gc/webconsole/public ./webconsole/public
COPY --from=builder /go/src/free5gc/config/webuicfg.yaml ./config/

WORKDIR /free5gc/webconsole
