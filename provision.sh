#!/usr/bin/env bash

# Use root user
# sudo su

# Update YUM base on CentOS 8.0
sudo yum update -y

source /etc/locale.conf

# Install Apache 2.4.13
sudo yum install -y httpd mod_ssl
sudo service httpd start

# Install Postfix 3.3.1
sudo yum install -y postfix

# Install PGSQL 10.6
sudo yum install -y postgresql postgresql-server postgresql-contrib

# Install PHP 7.3.13
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo yum module enable -y php:remi-7.3
sudo yum install -y php php-cli php-common \
    php-intl \
    php-mbstring \
    php-pdo \
    php-pdo_sqlite \
    php-pdo_pgsql \
    php-soap \
    php-zip \
    php-gd \
# Create user with root priviledged
sudo adduser admin
# Change password for account admin
sudo echo admin | passwd --stdin admin
# passwd admin
# Add user to sudo group
sudo usermod -aG wheel admin

# TODO: Use below command to change system locale
sudo yum -y install glibc-locale-source glibc-langpack-en
sudo localedef -i ja_JP -c -f EUC-JP -A /usr/share/locale/locale.alias ja_JP.EUC-JP
sudo localectl set-locale LANG=ja_JP.eucjp
export LANG=ja_JP.eucjp
source /etc/locale.conf
export PGSETUP_INITDB_OPTIONS="--pgdata=/var/lib/pgsql/data/ -E 'EUC-JP' --lc-collate='ja_JP.eucjp' --lc-ctype='ja_JP.eucjp'"
sudo postgresql-setup --initdb --unit postgresql
sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service 

# Change permission for database
sudo cp /vagrant/postgres/genkou_traveler_eccube_db_20200108001.dump /opt/
sudo chown postgres:postgres /vagrant/postgres/genkou_traveler_eccube_db_20200108001.dump

# Init Postgres database
sudo -u postgres psql -c "alter user postgres with password 'postgres';"
# Todo: Use below command to create your custom DB
# TODO: Use below command for LOCALE EUC_JP
sudo -u postgres psql -c "create database traveler_eccube_db ENCODING='EUC_JP' LC_COLLATE = 'ja_JP.eucjp' LC_CTYPE = 'ja_JP.eucjp'"
# TODO: Change user name
sudo -u postgres psql -c "create user traveler_eccube;"
sudo -u postgres psql -c "create user traveler_eccube_readonly;"
sudo -u postgres psql -c "ALTER ROLE traveler_eccube WITH password 'SxpDWlB8'"
sudo -u postgres psql -c "ALTER ROLE traveler_eccube_readonly WITH password 'SxpDWlB8'"
sudo -u postgres psql -c "grant all privileges on database traveler_eccube_db to traveler_eccube;"
# TODO: Import psql file into newly created database
# TODO: Create folder postgres which content postgresql file
sudo -u postgres psql -d traveler_eccube_db -f /opt/genkou_traveler_eccube_db_20200108001.dump
sudo -u postgres psql -d traveler_eccube_db -c "DELETE FROM \"public\".\"dtb_member\" WHERE login_id = 'admin';"
sudo -u postgres psql -d traveler_eccube_db -c "INSERT INTO \"public\".\"dtb_member\"(\"member_id\", \"name\", \"department\", \"login_id\", \"password\", \"authority\", \"rank\", \"work\", \"del_flg\", \"creator_id\", \"update_date\", \"create_date\", \"login_date\", \"password_error_flg\") VALUES ((SELECT max(member_id) + 1 FROM dtb_member), 'ADMIN', 'ADMIN', 'admin', '2c19f4a742398150cecc80b3e76b673a35b8c19c', 1, 3, 1, 0, 0, NOW(), NOW(), NULL, 2);"

# Config vhost for server
# Ex: sol_traveler_ec folder is /var/www/sol_traveler_ec
sudo cp /vagrant/apache/httpd/sol_traveler_ec-site.conf /etc/httpd/conf.d/sol_traveler_ec-site.conf
sudo cp /vagrant/apache/httpd/sol_traveler_ec-site-ssl.conf /etc/httpd/conf.d/sol_traveler_ec-site-ssl.conf

# Auto start httpd service 
sudo systemctl enable httpd.service
sudo systemctl daemon-reload
# Copy generated ssl certificate
sudo mkdir -p /etc/httpd/ssl/sol_traveler_ec
sudo cp -r /vagrant/apache/ssl/. /etc/httpd/ssl/sol_traveler_ec
sudo systemctl restart httpd.service

# Auto start postgresql service
sudo systemctl postgresql start
sudo systemctl enable postgresql

# Disable SELinux due to limitation of vagrant sync feature
sudo setenforce 0

# Free postgres access
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf
sudo sed -i "s/display_errors = Off/display_errors = On/g" /etc/php.ini
sudo echo "host  all  all 0.0.0.0/0 md5" | sudo tee -a /var/lib/pgsql/data/pg_hba.conf
sudo service postgresql restart

# Postfix
sudo chkconfig postfix on

# Generate ssl
# sudo mkdir -p /etc/httpd/ssl/sol_traveler_ec
# sudo cd /etc/httpd/ssl/sol_traveler_ec
# sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout server.key -out server.crt
# sudo service httpd restart

# Rename default php.ini
sudo mv /etc/php.ini /etc/php.ini.bak
# Copy file php.ini
sudo cp /vagrant/php/php.ini /etc/php.ini
sudo service httpd restart

# Rename default postgresql configuration
sudo mv /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.bak
sudo mv /var/lib/pgsql/data/pg_ident.conf /var/lib/pgsql/data/pg_ident.conf.bak
sudo mv /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.bak
sudo mv /var/lib/pgsql/data/postmaster.opts /var/lib/pgsql/data/postmaster.opts.bak
# Move postgresql configuration
sudo cp -r /vagrant/postgres/config/. /var/lib/pgsql/data/
sudo chown -R postgres:postgres /var/lib/pgsql/data/.
sudo service postgresql restart