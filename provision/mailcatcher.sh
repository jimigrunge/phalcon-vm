#!/bin/bash


echo "Mailcatcher Script..."

mailcatcher_setup() {
  # Mailcatcher
  #
  # Installs mailcatcher using RVM. RVM allows us to install the
  # current version of ruby and all mailcatcher dependencies reliably.
  local pkg
  local rvm_version
  local mailcatcher_version

  rvm_version="$(/usr/bin/env rvm --silent --version 2>&1 | grep 'rvm ' | cut -d " " -f 2)"
  if [[ -n "${rvm_version}" ]]; then
    pkg="RVM"
    print_pkg_info "$pkg" "$rvm_version"
  else
    # RVM key D39DC0E3
    # Signatures introduced in 1.26.0
    gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys D39DC0E3
    gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys BF04FF17

    printf " * RVM [not installed]\n Installing from source"
    curl --silent -L "https://raw.githubusercontent.com/rvm/rvm/stable/binscripts/rvm-installer" | sudo bash -s stable --ruby --quiet-curl
    source "/usr/local/rvm/scripts/rvm"
  fi

  mailcatcher_version="$(/usr/bin/env mailcatcher --version 2>&1 | grep 'mailcatcher ' | cut -d " " -f 2)"
  if [[ -n "${mailcatcher_version}" ]]; then
    pkg="Mailcatcher"
    print_pkg_info "$pkg" "$mailcatcher_version"
  else
    echo " * Mailcatcher [not installed]"
    /usr/bin/env rvm default@mailcatcher --create do gem install mailcatcher --no-rdoc --no-ri
    /usr/bin/env rvm wrapper default@mailcatcher --no-prefix mailcatcher catchmail
  fi

  if [[ -f "/etc/init/mailcatcher.conf" ]]; then
    echo " * Mailcatcher upstart already configured."
  else
    cp "/srv/config/init/mailcatcher.conf"  "/etc/init/mailcatcher.conf"
    echo " * Copied /srv/config/init/mailcatcher.conf    to /etc/init/mailcatcher.conf"
  fi

  if [[ -f "/etc/php/7.0/mods-available/mailcatcher.ini" ]]; then
    echo " * Mailcatcher php7 fpm already configured."
  else
    cp "/srv/config/php-config/mailcatcher.ini" "/etc/php/7.0/mods-available/mailcatcher.ini"
    echo " * Copied /srv/config/php-config/mailcatcher.ini    to /etc/php/7.0/mods-available/mailcatcher.ini"
  fi 
  
  ServiceFile="/lib/systemd/system/mailcatcher.service"
  
  if [[ -f $ServiceFile ]]; then
    echo " * MailCatcher service definition already exists"
  else 
    echo " * Writing MailCatcher service definition"
    # Write services file
cat > $ServiceFile <<EndOfText
[Unit]
Description=MailCatcher Service
After=network.service vagrant.mount

[Service]
Type=simple
ExecStart=/usr/local/rvm/bin/mailcatcher --foreground --ip 0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
EndOfText

    echo "enabling mailcatcher service"
    # Create symlink to availabel folder
    systemctl enable mailcatcher.service
    echo "Reloading service daemon"
    # Reload services daemon
    systemctl daemon-reload
    echo "Starting mailcatcher service"
    # Start service
    systemctl restart mailcatcher.service
  
  fi

}
mailcatcher_setup
