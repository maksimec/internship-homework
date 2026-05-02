FROM alpine:3.21

RUN apk add --no-cache \
    bash \
    coreutils \
    procps-ng \
    grep \
    sed \
    gawk \
    supervisor

WORKDIR /opt/monitor

COPY disk_monitor.sh     /usr/local/bin/disk_monitor.sh
COPY ram_monitor.sh      /usr/local/bin/ram_monitor.sh
COPY log_watcher.sh      /usr/local/bin/log_watcher.sh
COPY disk_monitor_worker.sh /usr/local/bin/disk_monitor_worker.sh
COPY ram_monitor_worker.sh  /usr/local/bin/ram_monitor_worker.sh
COPY supervisord.conf    /etc/supervisord.conf

RUN chmod +x \
    /usr/local/bin/disk_monitor.sh \
    /usr/local/bin/ram_monitor.sh \
    /usr/local/bin/log_watcher.sh \
    /usr/local/bin/disk_monitor_worker.sh \
    /usr/local/bin/ram_monitor_worker.sh

VOLUME ["/var/log/monitor"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
