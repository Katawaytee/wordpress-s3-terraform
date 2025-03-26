#!/bin/bash

cd /home/ubuntu

sudo echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+mCCPPAKSJM1Wi4mKPScPiYnBUP1pfwyXjoQrkRhae admin@LAPTOP-M2G07I2J >> /home/ubuntu/.ssh/authorized_keys
sudo echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODaHqtrCOBpfD+meWggDG5gFEqnNDtpxnqQ7xWIfXfL cloud-wordpress >> /home/ubuntu/.ssh/authorized_keys

# Wordpress setup ------------------------------------------------------------------------------------------
sudo apt update -y
sudo apt install -y apache2

wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz -C /home/ubuntu

cp /home/ubuntu/wordpress/wp-config-sample.php /home/ubuntu/wordpress/wp-config.php

sudo sed -i "s/define( 'DB_NAME', '[^']*' );/define( 'DB_NAME', '${database_name}' );/" /home/ubuntu/wordpress/wp-config.php
sudo sed -i "s/define( 'DB_USER', '[^']*' );/define( 'DB_USER', '${database_user}' );/" /home/ubuntu/wordpress/wp-config.php
sudo sed -i "s/define( 'DB_PASSWORD', '[^']*' );/define( 'DB_PASSWORD', '${database_pass}' );/" /home/ubuntu/wordpress/wp-config.php
sudo sed -i "s/define( 'DB_HOST', '[^']*' );/define( 'DB_HOST', '${private_instance_ip}' );/" /home/ubuntu/wordpress/wp-config.php

sudo apt install -y php8.3 libapache2-mod-php php-mysql php-curl php-xml php-gd

# Plugin setup ------------------------------------------------------------------------------------------
cat <<EOK > plugin.txt

define('FS_METHOD', 'direct');

define( 'AS3CF_SETTINGS', serialize( array(
    'provider' => 'aws',
    'access-key-id' => '${access_key}',
    'secret-access-key' => '${secret}',
    'bucket' => '${bucket_name}',
    'region' => '${region}',
    'copy-to-s3' => true,
    'serve-from-s3' => true,
    'domain' => 'path',
    'enable-object-prefix' => false,
    'use-yearmonth-folders' => false,
    'object-versioning' => false
) ) );
EOK

sudo sed -i '/\/\* Add any custom values between this line and the "stop editing" line. \*\//r plugin.txt' /home/ubuntu/wordpress/wp-config.php

sudo cp -r wordpress/* /var/www/html

sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 775 /var/www/html/wp-content

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

cd /var/www/html
sudo -u www-data wp core install \
  --url="http://${app_instance_ip}" \
  --title="Wordpress with S3 Site" \
  --admin_user="${admin_user}" \
  --admin_password="${admin_pass}" \
  --admin_email="admin@example.com" \
  --skip-email

sudo -u www-data wp plugin install amazon-s3-and-cloudfront --activate

sudo systemctl restart apache2