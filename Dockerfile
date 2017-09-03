FROM lsiobase/xenial

# global environment settings
ENV PLEXDRIVE_VERSION="5.0.0"
ENV PLATFORM_ARCH="amd64"

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.name="rclone-mount" \
      org.label-schema.description="Mount cloud storage using rclone, unionfs-fuse, and Docker." \
      org.label-schema.vcs-url="https://github.com/jdavis92/rclone-mount.git" \
      org.label-schema.docker.cmd="docker run -d --name rclone-mount --cap-add SYS_ADMIN --device /dev/fuse -e RCLONE_REMOTE="" -v /local/path/to/rclone.conf:/root/.rclone.conf jdavis92/rclone-mount" \
      org.label-schema.docker.param="RCLONE_REMOTE=Name of rclone remote to mount, SCHEDULE=CRON schedule for persisting changes, MOUNT_UID=UID for mounted files, MOUNT_GID=GID for mounted files"

RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    fuse \
    unionfs-fuse \
    wget \
    unzip \
    && cd /tmp \
    && wget -q https://downloads.rclone.org/rclone-current-linux-${PLATFORM_ARCH}.zip \
    && unzip rclone-current-linux-${PLATFORM_ARCH}.zip \
    && mv rclone-*-linux-${PLATFORM_ARCH}/rclone /usr/bin/ \
    && rm -r rclone-* \
    && wget -q https://github.com/dweidenfeld/plexdrive/releases/download/${PLEXDRIVE_VERSION}/plexdrive-linux-${PLATFORM_ARCH} \
    && mv /tmp/plexdrive-linux-${PLATFORM_ARCH} /usr/bin/plexdrive

ADD ./scripts /usr/local/bin
ADD ./s6 /etc/s6
RUN chmod +x /etc/s6/plexdrive/finish \
    && chmod +x /etc/s6/plexdrive/run \
    && chmod +x /etc/s6/rclone/finish \
    && chmod +x /etc/s6/rclone/run \
    && chmod +x /etc/s6/unionfs/finish \
    && chmod +x /etc/s6/unionfs/run \
    && chmod +x /etc/s6/cron/run \
    && chmod +x /etc/s6/.s6-svscan/finish \
    && chmod +x /usr/local/bin/purge-deleted \
    && chmod +x /usr/local/bin/upload

ENV MOUNT_UID="1000" \
    MOUNT_GID="1000" \
    RCLONE_REMOTE="" \
    SCHEDULE="0 9 * * *"

VOLUME ["/mnt/unionfs", "/tmp/local", "/mnt/rclone", "/mnt/plexdrive"]

CMD ["/bin/s6-svscan", "/etc/s6"]
