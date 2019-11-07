#!/bin/bash
# NOTE: Need to source this file to get the export to work (see: https://stackoverflow.com/questions/10781824/export-not-working-in-my-shell-script)

ISTIO_INSTALL_BASE="/usr/local/bin/"

ISTIO_VERSION="1.0.5"
ISTIO_DIR="istio-${ISTIO_VERSION}"

ISTIO_HOME="${ISTIO_INSTALL_BASE}${ISTIO_DIR}"

if [ -d "$ISTIO_HOME" ]; then
  # Take action if $DIR exists. #
  echo "Istio installed."
else
  echo "Installing Istio here: $ISTIO_HOME"
  # Mac OS:
  cd $ISTIO_INSTALL_BASE
  echo "Downloading https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-osx.tar.gz"
  curl -L "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-osx.tar.gz" | tar xz
fi

export ISTIO_HOME=$ISTIO_HOME
export DEMO_HOME=/Users/marc.hildenbrand/Documents/Development/istio-tutorial

# add ISTIO to PATH
echo "Adding $ISTIO_HOME/bin to path"
export PATH=$ISTIO_HOME/bin:$PATH
