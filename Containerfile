#
# Copyright (c) 2023 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

FROM registry.access.redhat.com/ubi9/ubi:9.2 AS builder

# Install packages:
RUN \
  dnf install -y \
  make \
  && \
  dnf clean all

# Currently RHEL 9 doesn't provide a Go 1.21 compiler, so we need to install it from the Go
# downloads site:
RUN \
  curl -Lo tarball https://go.dev/dl/go1.21.3.linux-amd64.tar.gz && \
  echo 1241381b2843fae5a9707eec1f8fb2ef94d827990582c7c7c32f5bdfbfd420c8 tarball | sha256sum -c && \
  tar -C /usr/local -xf tarball && \
  rm tarball

# Run the rest of the steps with a new builder user:
RUN \
  useradd -c "Builder" builder
USER \
  builder
WORKDIR \
  /home/builder
ENV \
  PATH="${PATH}:/usr/local/go/bin"

# Copy the source:
COPY \
  --chown=builder:builder \
  . /home/builder

# Download the Go dependencies. We do this in a separate step so that hopefully that large set of
# dependencies will be in a cached layer, and we will not need to download them for every build.
RUN \
  go mod download

# Build the binary:
RUN \
  make binary

FROM registry.access.redhat.com/ubi9-minimal:9.2 AS runtime

COPY \
  --from=builder \
 /home/builder/o2ims /usr/bin/o2ims

ENTRYPOINT \
  /usr/bin/o2ims
