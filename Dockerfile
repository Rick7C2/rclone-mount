FROM alpine:3.5

# global environment settings
ENV PLEXDRIVE_VERSION="5.0.0"
ENV PLATFORM_ARCH="amd64"

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.name="rclone-mount" \
      org.label-schema.description="Mount cloud storage using rclone, unionfs-fuse, and Docker." \
      org.label-schema.vcs-url="https://github.com/jdavis92/rclone-mount.git" \
      org.label-schema.docker.cmd="docker run -d --name rclone-mount --cap-add SYS_ADMIN --device /dev/fuse -e RCLONE_REMOTE="" -v /local/path/to/rclone.conf:/root/.rclone.conf jdavis92/rclone-mount" \
      org.label-schema.docker.param="RCLONE_REMOTE=Name of rclone remote to mount, SCHEDULE=CRON schedule for persisting changes, MOUNT_UID=UID for mounted files, MOUNT_GID=GID for mounted files"

RUN apk add --no-cache \
    bash \
    ca-certificates \
    fuse \
    s6 \
    unionfs-fuse \
    wget \
    && cd /tmp \
    && wget -q https://downloads.rclone.org/rclone-current-linux-${PLATFORM_ARCH}.zip \
    && unzip rclone-current-linux-${PLATFORM_ARCH}.zip \
    && mv rclone-*-linux-${PLATFORM_ARCH}/rclone /usr/bin/ \
    && rm -r rclone-* \
    && wget -q https://github.com/dweidenfeld/plexdrive/releases/download/${PLEXDRIVE_VERSION}/plexdrive-linux-${PLATFORM_ARCH} \
    && mv /tmp/plexdrive-linux-${PLATFORM_ARCH} /usr/bin/plexdrive \
    && chown root:root /usr/bin/rclone \
    && chmod 755 /usr/bin/rclone \
    && chown root:root /usr/bin/plexdrive \
    && chmod 755 /usr/bin/plexdrive

ADD ./scripts /usr/local/bin
ADD ./s6 /etc/s6
RUN chmod -R 755 /usr/local/bin \
    && chmod -R 755 /etc/s6/plexdrive/finish
    && chmod -R 755 /etc/s6/plexdrive/run
    && chmod -R 755 /etc/s6/rclone/finish
    && chmod -R 755 /etc/s6/rclone/run
    && chmod -R 755 /etc/s6/unionfs/finish
    && chmod -R 755 /etc/s6/unionfs/run
    && chmod -R 755 /etc/s6/cron/run
    && chmod -R 755 /etc/s6/.s6-svscan/finish

ENV MOUNT_UID="1000" \
    MOUNT_GID="1000" \
    RCLONE_REMOTE="" \
    SCHEDULE="0 9 * * *"

VOLUME ["/mnt/unionfs", "/tmp/local", "/mnt/rclone", "/mnt/plexdrive"]

CMD ["/bin/s6-svscan", "/etc/s6"]
