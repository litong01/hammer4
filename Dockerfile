FROM alpine:3.20.1 as BUILDER

RUN apk add curl && mkdir -p /work/bin && cd /work && \
    ARCH=$(uname -m) && if [[ "${ARCH}" == "aarch64" ]]; then ARCH=arm64; fi && \
    if [[ "${ARCH}" == "x86_64" ]]; then ARCH="amd64"; fi && \
    echo "Download kubectl..." && \
    curl -Lso kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    chmod +x kubectl && mv kubectl /work/bin/kubectl && \
    echo "Downloading kustomize 5.4.2 ..." && \
    curl -Lso kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v5.4.2/kustomize_v5.4.2_linux_${ARCH}.tar.gz && \
    echo "Expand kustomize 5.4.2 ..." && \
    tar -xf kustomize.tar.gz && mv kustomize /work/bin/kustomize && \
    echo "Download helm..." && \
    curl -Lso helm.tar.gz https://get.helm.sh/helm-v3.15.2-linux-${ARCH}.tar.gz && \
    echo "Expand helm..." && \
    tar -xf helm.tar.gz && mv linux-${ARCH}/helm /work/bin/helm && \
    echo "Download istioctl..." && \
    curl -Lso istioctl.tar.gz https://github.com/istio/istio/releases/download/1.22.2/istio-1.22.2-linux-${ARCH}.tar.gz && \
    echo "Expand istioctl..." && \
    tar -xf istioctl.tar.gz && \
    echo "Move istioctl..." && \
    mv istio-1.22.2/bin/istioctl /work/bin/istioctl

RUN apk add --update --no-cache go=1.22.5-r0
RUN go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.15.0
RUN go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

FROM email4tong/kind:v0.23.0 as KINDSOURCE

FROM alpine:3.20.1
LABEL maintainer="litong01"

RUN apk add --update --no-cache bash docker-cli git make openssl \
    diffutils jq yq go docker-cli-buildx k9s

COPY --from=BUILDER /work/bin/* /home/bin/
COPY --from=BUILDER /root/go/bin/controller-gen /home/bin
COPY --from=BUILDER /root/go/bin/setup-envtest /home/bin
COPY ./main.sh /home/bin
COPY --from=KINDSOURCE /usr/local/bin/kind /home/bin
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/* && apk update
RUN apath=$(/home/bin/setup-envtest use 1.26.0 --bin-dir /home/bin -p path) && \
    mv ${apath}/kube-apiserver /home/bin/k8s/ && \
    mv ${apath}/etcd /home/bin/k8s/ && \
    mv ${apath}/kubectl /home/bin/k8s/ && rm -rf ${apath}

ENV PATH $PATH:/home/bin
ENV HOME=/home
ENV KUBEBUILDER_ASSETS /home/bin/k8s
ENV TEST_ASSET_KUBE_APISERVER /home/bin/k8s/kube-apiserver
ENV TEST_ASSET_ETCD /home/bin/k8s/etcd
ENV TEST_ASSET_KUBECTL /home/bin/k8s/kubectl

WORKDIR /home
CMD /home/bin/main.sh