FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y && \
    apt install -y git curl wget maven build-essential python3 graphviz && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.deb && \
    apt update && \
    apt install -y ./jdk-25_linux-x64_bin.deb && \
    rm jdk-25_linux-x64_bin.deb && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://go.dev/dl/go1.25.2.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.25.2.linux-amd64.tar.gz && \
    rm go1.25.2.linux-amd64.tar.gz

ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
ENV GO111MODULE=on

RUN mkdir -p /go/bin && \
    /usr/local/go/bin/go install golang.org/x/tools/cmd/stress@latest && \
    /usr/local/go/bin/go install golang.org/x/perf/cmd/benchstat@latest

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /workspace
USER root