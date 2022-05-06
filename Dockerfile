FROM quay.io/centos/centos:stream8

# from https://pagure.io/centos-sig-hyperscale/containers-releng/blob/main/f/Containerfile

RUN dnf -y install tar gzip gcc make curl buildah fuse-overlayfs; rm -rf /var/cache /var/log/dnf* /var/log/yum.*

ADD https://raw.githubusercontent.com/containers/buildah/main/contrib/buildahimage/stable/containers.conf /etc/containers/

# Adjust storage.conf to enable Fuse storage.
RUN sed -i /etc/containers/storage.conf \
        -e 's|^#mount_program|mount_program|g' \
        -e '/additionalimage.*/a "/var/lib/shared",'

RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers \
 && touch /var/lib/shared/overlay-images/images.lock \
          /var/lib/shared/overlay-layers/layers.lock

ENV BUILDAH_ISOLATION=chroot

RUN echo build:2000:50000 > /etc/subuid \
 && echo build:2000:50000 > /etc/subgid

COPY build.sh build

#RUN chgrp -R 0 $HOME && \ 
#         chmod -R g=u $HOME

RUN chmod +x build

ENTRYPOINT ["./build"]
CMD ["build"]

