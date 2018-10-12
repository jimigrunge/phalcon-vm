#!/bin/bash

if [[ -f "/srv/www/default/vagrant-home/custom-my.cnf" ]]; then
  cp "/srv/www/default/vagrant-home/custom-my.cnf" "/etc/mysql/my.cnf"
  echo " * Copied /srv/www/default/vagrant-home/custom-my.cnf to /etc/mysql/my.cnf"
else
  echo " * Using default my.cnf file."
fi

restart() {
	if service --status-all | grep -Fq ${1}; then
		service ${1} restart
	fi
}

restart nginx
restart varnish
restart php7.0-fpm
restart mysql
restart postgresql
restart mongodb
restart redis-server
restart memcached
restart gearman-job-server
restart rabbitmq-server
restart sphinxsearch
