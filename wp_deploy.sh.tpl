#!/bin/bash

set -e
echo "Starting WordPress installation" >> ~/debug.log

sudo apt update && sudo apt upgrade -y
sudo apt install -y curl apache2 php php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-zip php-xmlrpc php-cli wget unzip >> ~/debug.log 2>&1

# installation WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar >> ~/debug.log 2>&1
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
wp --info >> ~/debug.log 2>&1

# installation WordPress
cd /var/www/html
sudo wget https://wordpress.org/latest.zip >> ~/debug.log 2>&1
sudo unzip latest.zip >> ~/debug.log 2>&1
sudo mv wordpress/* . >> ~/debug.log 2>&1
sudo rm -rf wordpress latest.zip >> ~/debug.log 2>&1
sudo rm index.html

# configuring permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# setting up env vars
echo "export DB_NAME='wordpressdb'" | sudo tee -a /etc/environment
echo "export DB_USER='admin'" | sudo tee -a /etc/environment
echo "export DB_PASSWORD='password123'" | sudo tee -a /etc/environment
echo "export DB_HOST='${db_host}'" | sudo tee -a /etc/environment
echo "export WP_REDIS_HOST='${redis_host}'" | sudo tee -a /etc/environment
echo "export WP_REDIS_PORT='6379'" | sudo tee -a /etc/environment
echo "export WP_CACHE_KEY_SALT='${cache_key_salt}'" | sudo tee -a /etc/environment



# resetting env 
source /etc/environment

# creating wp-config.php via WP-CLI
sudo wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASSWORD --dbhost=$DB_HOST --path=/var/www/html --allow-root >> ~/debug.log 2>&1

wp config set WP_REDIS_HOST "$(echo $WP_REDIS_HOST)" --type=constant --allow-root && \
wp config set WP_REDIS_PORT "$(echo $WP_REDIS_PORT)" --type=constant --raw --allow-root && \
wp config set WP_CACHE_KEY_SALT "$(echo $WP_CACHE_KEY_SALT)" --type=constant --allow-root && \
wp config set WP_REDIS_MAXTTL 86400 --type=constant --raw --allow-root && \
wp config set AUTH_KEY "XAV|u2/s3_qyK]~HO\!fwpBm9(No|W<H@w}4=o@5nB_*M1[xS7Ov$:*:%>U5+ Tjs" --type=constant --allow-root && \
wp config set SECURE_AUTH_KEY "5XP8}d4BKjQc+_qRx6bDMGv7O$RtC]DlPCd^(#J#>8A*?OmA7f]SYtZr#_jrt~1oy" --type=constant --allow-root && \
wp config set LOGGED_IN_KEY "<N)dMyYrwdL$)H4^3?T|Za3m=4f|heu^L^+cv6qo}92o<HKIQWH#@9aVLI^q-5d?" --type=constant --allow-root && \
wp config set NONCE_KEY "=jHo\\4_6[j\\4^6%LG\$[f%K+,Rt+N\\!w^9ZqAvQkmY5FB#8HSf,txv:DTYbtJ.(&7:E" --type=constant --allow-root && \
wp config set AUTH_SALT "*&|HQr+o1L\!4e<iX[+9;UN\!sh#\!/WRn+dihd]n@I:Z]cPB}9r*=3u=3Y+3e+7\$E|" --type=constant --allow-root && \
wp config set SECURE_AUTH_SALT "BNg1Q9P>Dn\`+3\`rxeVbP9~TRqSFb0.61QS#R:!9Uf @.%$Gi+m,UvP#s0)Y1\`~.$" --type=constant --allow-root && \
wp config set LOGGED_IN_SALT "bcSNXbVc6b?9{U.}0=j7W),p+lr}+2(\$x9rRHW0?qG\$\[\$Hy_o0ZM@L\$\VZsIh\!@(a" --type=constant --allow-root && \
wp config set NONCE_SALT "aT@,o0~?^<\`=,BuPkb8z-dhG4BZwbf+hqqI@yg|Z\`o$,K|>0BVdtA,ZD|r5BVQIc" --type=constant --allow-root


# installation WordPress via WP-CLI
sudo wp core install --url="${url}" --title="My website title" --admin_user="admin" --admin_password="" --admin_email="admin@your-domain.com" --path=/var/www/html --allow-root >> ~/debug.log 2>&1

# creating task user
wp user create task task@example.com --user_pass="" --role="subscriber" --allow-root


# setting up and activation plugins
sudo wp plugin install redis-cache --activate --path=/var/www/html --allow-root >> ~/debug.log 2>&1
# sudo wp theme install twentytwentythree --activate --path=/var/www/html --allow-root >> ~/debug.log 2>&1

# restarting Apache
sudo systemctl restart apache2
sudo systemctl enable apache2
sudo systemctl status apache2 >> ~/debug.log 2>&1
echo "WordPress installation completed" >> ~/debug.log