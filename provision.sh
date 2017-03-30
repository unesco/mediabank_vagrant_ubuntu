#!/bin/bash -x

date > /etc/vagrant_box_build_time

# Apt-install various things necessary for EPrints, guest additions,
# etc., and remove optional things to trim down the machine.
apt-get -y update
apt-get -y upgrade
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install git vim-nox aptitude zlib1g-dev libssl-dev libreadline-dev libcurl4-openssl-dev libyaml-dev curl libexpat-dev libkrb5-dev node-less npm

# Installing Apache
apt-get -y install apache2

# Installing MySQL and it's dependencies, Also, setting up root password for MySQL as it will prompt to enter the password during installation
debconf-set-selections <<< 'mysql-server mysql-server/root_password password eprintsroot'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password eprintsroot'
aptitude -y install mysql-server

aptitude -y install mysql-client libmysqlclient-dev

# Installing Perl
aptitude -y install libapache2-mod-perl2

# Configure apache2 to load eprints
cp /opt/eprints3/vagrant/resources/apache_eprints.conf /etc/apache2/conf-available/eprints.conf
a2enconf eprints
a2enmod info
sed -i '/Allow from 192.0.2.0\/24/c\Require ip 192.168.0.0/16' /etc/apache2/mods-available/info.conf
sed -i '/Allow from 192.0.2.0\/24/c\Require ip 192.168.0.0/16' /etc/apache2/mods-available/status.conf
service apache2 reload

apt-get clean

# NPM dependences
npm install -g less
npm install -g less-plugin-clean-css
# for some strange reasons we need this
ln -s "$(which nodejs)" /usr/bin/node

# Installing the virtualbox guest additions. Uncomment if you encounter problems
# VBOX_VERSION=$(modinfo vboxguest | grep "^version:" - | sed -e 's/^[^\ ]*//g' | cut -f 1 -d "_" | tr -d '[[:space:]]')
# cd /tmp
# wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso -nv
# mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
# sh /mnt/VBoxLinuxAdditions.run <<< 'yes'
# umount /mnt
# rm VBoxGuestAdditions_$VBOX_VERSION.iso

# Setup sudo to allow no-password sudo for "admin"
echo "%sudo  ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create EPrints user
EPRINTS_USER="eprints"
EPRINTS_HOME="/opt/eprints3"
useradd --user-group --create-home --shell /bin/bash --groups adm,sudo --home-dir "${EPRINTS_HOME}" "${EPRINTS_USER}"
# Set Password to eprints
echo "${EPRINTS_USER}:${EPRINTS_USER}" | chpasswd
mkdir --mode 0700 --parents "${EPRINTS_HOME}/.ssh"
wget https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -nv -O "${EPRINTS_HOME}/.ssh/authorized_keys"
ssh-keyscan -H github.com >> "${EPRINTS_HOME}"/.ssh/known_hosts
chmod 600 "${EPRINTS_HOME}/.ssh/*"
cp /home/ubuntu/.bashrc "${EPRINTS_HOME}"
cp /home/ubuntu/.profile "${EPRINTS_HOME}"

# Install EPrints
cd "${EPRINTS_HOME}"
if [ -d "eprints" ]; then
    echo "It appears you already cloned eprints. Skipping..."
else
    echo "Cloning Eprints..."
    git clone https://github.com/eprints/eprints.git eprints
fi
# clone your repository here

# Install Perl dependences
cpan << ANSWERS
yes
local::lib
yes
ANSWERS

cpan install CPAN >/dev/null
cpan install YAML >/dev/null
cpan install Log::Log4perl >/dev/null
cpan install XML::Parser >/dev/null
cpan install XML::Simple >/dev/null
cpan install DBI >/dev/null
cpan install DBD::mysql >/dev/null
cpan install Net::LDAP >/dev/null
cpan install Image::Size >/dev/null
cpan install Geo::GeoNames >/dev/null
cpan install Authen::Krb5::Simple >/dev/null
cpan install URI >/dev/null
cpan install URI::OpenURL >/dev/null

su -c "source /opt/eprints3/vagrant/install_eprints.sh" eprints
