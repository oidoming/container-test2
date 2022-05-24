#!/bin/sh

# From https://pagure.io/centos-sig-hyperscale/containers-releng/blob/main/f/make-hyperscale-container.sh

releasever="$1"
[ -z "$releasever" ] && releasever='8'
dnf_opts="-y --setopt install_weak_deps=false"
packages='epel-release dnf dnf-plugins-core systemd'
if [ "$releasever" -eq 8 ]; then
  crb_repo="powertools"
  dnf_opts="$dnf_opts --disableplugin product-id"
else
  crb_repo="crb"
fi

summary="CentOS Stream $releasever test container XD"
 
if ! grep -q "CentOS Stream $releasever" /etc/os-release; then
  echo "You need to run this on a CentOS Stream $releasever host"
  exit 1
fi
 
script=$(mktemp)
trap 'rm -f $script' EXIT
 
# Hack to make these work with docker on el7
# https://access.redhat.com/solutions/6843481
export BUILDAH_FORMAT=docker
 
newcontainer=$(buildah from scratch)
 
cat > "$script" <<EOF
#!/bin/sh -x
scratchmnt=\$(buildah mount "$newcontainer")
dnf="dnf $dnf_opts --installroot \$scratchmnt"
\$dnf install --releasever "$releasever" $packages
\$dnf config-manager --set-enabled "$crb_repo"
\$dnf distro-sync
\$dnf clean all
buildah unmount "$newcontainer"
EOF
chmod +x "$script"
buildah unshare "$script"
 
buildah config \
  --created-by 'build.sh' \
  --label name='centos-test' \
  --label version="${releasever}" \
  --label architecture="$(uname -m)" \
  --label summary="${summary}" \
  --label description="${description}" \
  --label io.k8s.display-name="CentOS Stream ${releasever} test" \
  --label io.k8s.description="${description}" \
  --cmd '/bin/bash' \
  "$newcontainer"
buildah commit "$newcontainer" "centos-stream-${releasever}-test"
buildah rm "$newcontainer"
 
exit 0
