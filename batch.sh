# Use root user to prevent re-type "sudo"
# sudo su

# Update YUM base on CentOS 8.0
sudo yum update -y

# If system locale is not EUC-JP
# Use below command to change system locale
# localedef -c -f EUC_JP -i ja_JP ja_JP.EUC_JP
# export LC_ALL=ja_JP.EUC_JP

# Install Apache 2.4.13
sudo yum install -y httpd mod_ssl
# Show apache version
httpd -v
sudo service httpd start

# Install Postfix 3.3.1
sudo yum install -y postfix
# Show postfix version
postconf mail_version

# Install PGSQL 10.6
sudo yum install -y postgresql postgresql-server postgresql-contrib
# Show posgres version
psql -V

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
# Show php version
php -v

# Create user with root priviledged
sudo adduser giftland-admin
# Change password for account giftland-admin
sudo echo admin | passwd --stdin giftland-admin
# Add user to sudo group
sudo usermod -aG wheel giftland-admin

sudo postgresql-setup --initdb --unit postgresql
sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service 

# Init Postgres database
sudo -u postgres psql -c "alter user postgres with password 'postgres';"
# Todo: Use below command to create your custom DB
sudo -u postgres psql -c "create database traveler_eccube_db;"
# TODO: Use below command for LOCALE EUC_JP
# su postgres -c "createdb 'traveler_eccube_db' --encoding='EUC_JP'"
# TODO: Change user name
sudo -u postgres psql -c "create user traveler_eccube;"
sudo -u postgres psql -c "ALTER ROLE traveler_eccube WITH password 'SxpDWlB8'"
sudo -u postgres psql -c "grant all privileges on database traveler_eccube_db to giftland;"

# Dump giftland database
# Copy postgres sql file into psql folder
# sudo -u postgres psql -d giftland_db -f /vagrant/postgres/genkou_traveler_eccube_db_20200108001.dump

# Config vhost for server
# Ex: Giftland folder is /var/www/sol_traveler_ec
sudo cp ./apache/httpd/sol_traveler_ec-site.conf /etc/httpd/conf.d/sol_traveler_ec-site.conf
sudo cp ./apache/httpd/sol_traveler_ec-site-ssl.conf /etc/httpd/conf.d/sol_traveler_ec-site-ssl.conf

# Auto start httpd service 
sudo systemctl enable httpd.service
sudo systemctl daemon-reload
sudo systemctl restart httpd.service

# Auto start postgresql service
sudo systemctl postgresql start
sudo systemctl enable postgresql

# If there is error with permission
# Disable SELinux due to limitation of vagrant sync feature
# sudo setenforce 0

# Free postgres access
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf
sudo echo "host  all  all 0.0.0.0/0 md5" | sudo tee -a /var/lib/pgsql/data/pg_hba.conf
sudo service postgresql restart

# Postfix
sudo chkconfig postfix on