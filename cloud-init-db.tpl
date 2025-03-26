#!/bin/bash

cd /home/ubuntu

sudo echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+mCCPPAKSJM1Wi4mKPScPiYnBUP1pfwyXjoQrkRhae admin@LAPTOP-M2G07I2J >> /home/ubuntu/.ssh/authorized_keys
sudo echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODaHqtrCOBpfD+meWggDG5gFEqnNDtpxnqQ7xWIfXfL cloud-wordpress >> /home/ubuntu/.ssh/authorized_keys

sudo apt update -y
sudo apt install -y mariadb-server=1:10.11.*

sudo sed -i 's/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mariadb

sudo mysqladmin -u root password 'pass'

sudo MYSQL_PWD='pass' mysql -u root -e "
CREATE DATABASE IF NOT EXISTS ${database_name};
CREATE USER IF NOT EXISTS '${database_user}'@'%' IDENTIFIED BY '${database_pass}';
GRANT ALL PRIVILEGES ON ${database_name}.* TO '${database_user}'@'%';
FLUSH PRIVILEGES;
"