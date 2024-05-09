#FROM bitnami/golang:1.14.4 AS builder
FROM golang:1.18.10-buster AS builder

# Control-plane Supporting Packages
RUN apt-get update
RUN apt-get -y install wget git sudo

# User-plane Supporting Packages
#RUN apt-get update
#RUN apt-get -y install git gcc g++ cmake autoconf libtool pkg-config libmnl-dev libyaml-dev
#RUN go get -u github.com/sirupsen/logrus

# Get Free5GC source code
RUN cd $GOPATH/src \
    && git clone --recursive -b v3.3.0 -j `nproc` https://github.com/free5gc/free5gc.git

# Build all NFs
RUN cd $GOPATH/src/free5gc \
    && make

# Build the final image
FROM alpine

WORKDIR /free5gc

RUN mkdir -p config/ cert/ public

# Copy executables
COPY --from=builder /go/src/free5gc/bin/* ./

# Copy certificates and config files
COPY --from=builder /go/src/free5gc/config/* ./config/
COPY --from=builder /go/src/free5gc/cert/* ./cert/
