FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y git curl wget maven build-essential python3 python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.deb && \
    apt-get update && \
    apt-get install -y ./jdk-25_linux-x64_bin.deb && \
    rm jdk-25_linux-x64_bin.deb

RUN wget https://go.dev/dl/go1.25.2.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.25.2.linux-amd64.tar.gz && \
    rm go1.25.2.linux-amd64.tar.gz

ENV POETRY_HOME=/opt/poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    cd /usr/local/bin && \
    ln -s /opt/poetry/bin/poetry

ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin:/opt/poetry/bin
ENV GO111MODULE=on

WORKDIR /workspace
USER root
