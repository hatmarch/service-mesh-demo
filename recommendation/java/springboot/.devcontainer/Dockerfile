FROM fabric8/java-jboss-openjdk8-jdk:1.3.1
ENV AB_OFF=true
ENV JAVA_APP_DIR=/deployments
ENV JAEGER_SERVICE_NAME=recommendation\
  JAEGER_ENDPOINT=http://jaeger-collector.istio-system.svc:14268/api/traces\
  JAEGER_PROPAGATION=b3\
  JAEGER_SAMPLER_TYPE=const\
  JAEGER_SAMPLER_PARAM=1
EXPOSE 8080 8778 9779

USER root

RUN yum -y update && yum -y install bash && \
  #yum -y install kubernetes-client-1.5.2-0.7.git269f928.el7.x86_64 && \
  yum -y install wget

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
  chmod +x ./kubectl && mv ./kubectl /usr/bin/kubectl

RUN wget -qO- https://storage.googleapis.com/kubernetes-helm/helm-v2.12.2-linux-amd64.tar.gz | \
  tar -xzvf - && mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64

# Configuration for the Kubernetes plugin
RUN mkdir -p /root/.vscode-server/data/Machine && echo '{ \
    "vs-kubernetes": { \
        "vs-kubernetes.namespace": "", \
        "vs-kubernetes.kubectl-path": "/usr/bin/kubectl", \
        "vs-kubernetes.helm-path": "", \
        "vs-kubernetes.draft-path": "", \
        "vs-kubernetes.minikube-path": "", \
        "vs-kubernetes.kubectlVersioning": "user-provided", \
        "vs-kubernetes.outputFormat": "yaml", \
        "vs-kubernetes.kubeconfig": "", \
        "vs-kubernetes.knownKubeconfigs": [], \
        "vs-kubernetes.autoCleanupOnDebugTerminate": false, \
        "vs-kubernetes.nodejs-autodetect-remote-root": true, \
        "vs-kubernetes.nodejs-remote-root": "", \
        "vs-kubernetes.nodejs-debug-port": 9229, \
        "checkForMinikubeUpgrade": true, \
        "logsDisplay": "webview", \
        "imageBuildTool": "Docker" \
    } \
}' > /root/.vscode-server/data/Machine/settings.json

CMD /bin/bash

