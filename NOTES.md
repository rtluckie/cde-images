useradd -m -s /bin/bash rluckie
echo 'rluckie ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
usermod -a -G root rluckiei
chmod -R g+w /home/linuxbrew/
chown -R :linuxbrew /home/linuxbrew/


useradd rluckie -m -G root -s /usr/bin/bash
echo 'rluckie ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
localedef -i en_US -f UTF-8 en_US.UTF-8 
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

export KDK_DOTFILES_REPO=https://github.com/rtluckie/dotfiles-yadm.git
export KDK_USERNAME=rluckie


====== 
# new packages

gox
lastpass

# failure

telnet


# copy from kdk

/usr/local/bin/awake
/usr/local/bin/provision-user
/usr/local/bin/start-dockerd
/lib/systemd/system/kdk-setup.service
