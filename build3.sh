#!/bin/sh

# from https://www.redhat.com/sysadmin/getting-started-buildah & https://www.redhat.com/sysadmin/building-buildah

set -o errexit

dnf_opts="-y --setopt install_weak_deps=false"

# Create a container
container=$(buildah from scratch)

# Labels are part of the "buildah config" command
buildah config --label maintainer="user123" $container

script=$(mktemp)
trap 'rm -f $script' EXIT

# Hack to make these work with docker on el7
# https://access.redhat.com/solutions/6843481
export BUILDAH_FORMAT=docker

newcontainer=$(buildah from scratch)

cat > "$script" <<EOF
#!/usr/bin/env bash 
mountpoint=\$(buildah mount "$newcontainer")
dnf="dnf $dnf_opts --installroot \$mountpoint"
\$dnf install --releasever 8 tar gzip gcc make curl
\$dnf distro-sync
\$dnf clean all
curl -sSL http://ftpmirror.gnu.org/hello/hello-2.10.tar.gz \
     -o /tmp/hello-2.10.tar.gz
tar xvzf /tmp/hello-2.10.tar.gz -C ${mountpoint}/opt
pushd ${mountpoint}/opt/hello-2.10
./configure
make
make install DESTDIR=${mountpoint}
popd
buildah unmount "$newcontainer"
EOF
chmod +x "$script"
buildah unshare "$script"

# Entrypoint, too, is a “buildah config” command
buildah config --entrypoint /usr/local/bin/hello $container

# Finally saves the running container to an image
buildah commit $container hello:latest
