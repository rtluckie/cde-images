FROM ubuntu:focal AS homebrew-base

LABEL maintainer="rluckie@cisco.com" \
      kdk=""

RUN apt -y update && \
    apt -y --no-install-recommends install \
        build-essential \
        ca-certificates \
        curl \
        locales \
        file \
        git \
        sudo && \
    apt -y clean && apt -y autoremove && rm -rf /var/lib/apt/lists/*

RUN useradd linuxbrew -m -G root -s /bin/bash \
	&& echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

USER linuxbrew
RUN sudo localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

FROM ciscosso/kdk:1.23.1 AS kdk-upstream

FROM ubuntu:focal AS final
COPY files/etc/profile.d /etc/profile.d

# RUN yes | unminimize \
RUN apt -y update \
    && apt -y --no-install-recommends install \
        apt-transport-https \
        bridge-utils \
        build-essential \
        ca-certificates \
        curl \
        file \
        git \
        locales \
        ntp \
        ntpdate \
        qemu-user-static \
        software-properties-common \
        sudo \
        systemd \
        systemd-sysv \
        xauth \
    && apt -y clean && apt -y autoremove && rm -rf /var/lib/apt/lists/*
COPY --from=homebrew-base /home/linuxbrew /home/linuxbrew
COPY files/brew_bundles /home/linuxbrew/bundles
RUN chmod -R g+w /home/linuxbrew/ \
    && chown -R root:root /home/linuxbrew

RUN /bin/bash -c 'localedef -i en_US -f UTF-8 en_US.UTF-8 && source /etc/profile && for fpath in /home/linuxbrew/bundles/*.brew; do brew bundle --verbose --file $fpath || :; done && brew cleanup'

COPY --from=kdk-upstream /lib/systemd/system/kdk-setup.service /lib/systemd/system/kdk-setup.service
COPY --from=kdk-upstream /usr/local/bin/awake /usr/local/bin/awake
COPY --from=kdk-upstream /usr/local/bin/kdk-setup.sh /usr/local/bin/kdk-setup.sh
COPY --from=kdk-upstream /usr/local/bin/provision-user /usr/local/bin/provision-user
COPY --from=kdk-upstream /usr/local/bin/start-dockerd /usr/local/bin/start-dockerd


#######################################
# Configure systemd and other Miscellaneous configuration bits
#  Mostly taken from:
#  https://github.com/dramaturg/docker-debian-systemd/blob/master/Dockerfile

RUN apt -y update && apt -y install openssh-server 
RUN echo "Configuring systemd" && \
        cd /lib/systemd/system/sysinit.target.wants/ && \
        ls | grep -v systemd-tmpfiles-setup.service | xargs rm -f && \
        rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
        systemctl mask -- \
            apt-daily-upgrade.timer \
            apt-daily.timer \
            e2scrub_all.timer \
            fstrim.timer \
            getty-static.service \
            getty.target \
            motd-news.timer \
            swap.swap \
            swap.target \
            systemd-ask-password-wall.path \
            systemd-logind.service \
            systemd-remount-fs.service \
            systemd-tmpfiles-setup.service \
            tmp.mount && \
        systemctl mask -- \
            cron.service \
            dbus.service \
            ntp.service && \
        systemctl set-default multi-user.target || true && \
        sed -ri /etc/systemd/journald.conf -e 's!^#?Storage=.*!Storage=volatile!' && \
        # Avoid port binding confict between dnsmasq and systemd-resolved && \
        sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf && \
        # Set locale && \
        localedef -i en_US -f UTF-8 en_US.UTF-8 && \
        # Configure openssh-server && \
        sed -i 's/#Port 22/Port 2022/' /etc/ssh/sshd_config && \
        # Configure docker daemon to support docker in docker && \
        mkdir /etc/docker && echo '{"storage-driver": "vfs"}' > /etc/docker/daemon.json


RUN systemctl enable kdk-setup.service && \
    ldconfig

RUN apt install -y dnsutils dnsmasq
#######################################
# Ensure systemd starts, which subsequently starts ssh and docker

EXPOSE 2022
CMD ["/lib/systemd/systemd"]