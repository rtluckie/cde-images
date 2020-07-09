FROM ubuntu:focal AS homebrew-base
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -qqy update && \
    apt-get -qqy --no-install-recommends install \
        build-essential \
        ca-certificates \
        curl \
        file \
        g++ \
        git \
        locales \
        sudo \
        uuid-runtime \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure locales \
	&& update-locale LANG=en_US.UTF-8 \
	&& useradd -m -s /bin/bash linuxbrew \
    && echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' | tee -a /etc/sudoers


USER linuxbrew
WORKDIR /home/linuxbrew
ENV LANG=en_US.UTF-8 \
	PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash
    
RUN CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" \
    && brew config \
    && brew update


FROM ubuntu:focal AS final

LABEL maintainer="rluckie@cisco.com" \
      kdk=""

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -qqy update && \
    yes | unminimize && unset DEBIAN_FRONTEND

RUN apt-get -qqy --no-install-recommends install \
        apt-transport-https \
        binutils \
        build-essential \
        ca-certificates \
        curl \
        file \
        g++ \
        git \
        gnupg \
        gnupg-agent \
        locales \
        make \
        software-properties-common \
        sudo \
        uuid-runtime \
        && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    add-apt-repository "deb https://packages.cloud.google.com/apt cloud-sdk main" && \
    apt-get -qqy update && \
    apt-get -qqy --no-install-recommends install \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        google-cloud-sdk

COPY --from=homebrew-base /home/linuxbrew /home/linuxbrew


RUN apt-get -qqy --no-install-recommends install \
        less \
        man-db \
        ntp \
        ntpdate \
        openssh-server \
        systemd \
        systemd-sysv \
        vim \
        zsh

# #######################################
# # Copy local files

COPY files/etc/profile.d /etc/profile.d
COPY files/home/linuxbrew/bundles /home/linuxbrew/bundles
COPY files/lib/systemd/system/ /lib/systemd/system/
COPY files/usr/local/bin/ /usr/local/bin/

RUN systemctl enable kdk-setup.service && ldconfig

# #######################################
# # Configure systemd and other Miscellaneous configuration bits
# #  Mostly taken from:
# #  https://github.com/dramaturg/docker-debian-systemd/blob/master/Dockerfile

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


RUN /bin/bash -c 'source /etc/profile && for b in /home/linuxbrew/bundles/auto/*.brew; do brew bundle --file $b; done'

RUN /bin/bash -c 'source /etc/profile && for b in /home/linuxbrew/bundles/manual/*.brew; do brew bundle --verbose --file $b; done'

RUN apt-get -qqy clean && apt-get -qqy autoremove && rm -rf /var/lib/apt/lists/* && \
    rm -fr /root/.cache/Homebrew/downloads && \
    /bin/bash -c 'source /etc/profile && brew cleanup' && \
    rm -fr /home/linuxbrew/.cache/Homebrew/ /root/.cache/Homebrew/

#######################################
# Ensure systemd starts, which subsequently starts ssh and docker
EXPOSE 2022
CMD ["/lib/systemd/systemd"]


# add emacs