FROM alpine:3.18.2 as BUILDER

RUN apk add curl && mkdir -p /work/bin && cd /work && \
    ARCH=$(uname -m) && if [[ "${ARCH}" == "aarch64" ]]; then ARCH=arm64; fi && \
    if [[ "${ARCH}" == "x86_64" ]]; then ARCH="amd64"; fi && \
    echo "Download kubectl..." && \
    curl -Lso kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    chmod +x kubectl && mv kubectl /work/bin/kubectl

FROM alpine:3.18.2
LABEL maintainer="litong01"

RUN apk add --update --no-cache bash docker-cli \
    jq yq docker-cli-buildx curl

COPY --from=BUILDER /work/bin/* /home/bin/
COPY ./main.sh /home/bin
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/* && apk update

ENV PATH $PATH:/home/bin
ENV HOME=/home

WORKDIR /home
CMD /home/bin/main.sh