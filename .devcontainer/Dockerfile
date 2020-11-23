FROM quay.io/mhildenb/dev-demo-base:1.1

USER root

# Update istio version over what's in the base
RUN curl -L https://github.com/istio/istio/releases/download/1.6.13/istioctl-1.6.13-linux-amd64.tar.gz | tar -zxvf - -C /usr/local/bin && chmod 755 /usr/local/bin/istioctl
    
USER jboss

# this is done in the base image already (to support the demo shell images too), but for those that make
# local changes to .zshrc they should not have to rebuild the base
COPY .zshrc.example $HOME/.zshrc

ENV DEMO_HOME /workspaces/service-mesh-demo