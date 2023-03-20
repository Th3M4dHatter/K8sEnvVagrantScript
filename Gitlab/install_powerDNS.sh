echo ==== Installing Power DNS =======================================
sudo apt update
sudo apt install -y curl vim

sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

ls -lh /etc/resolv.conf 
sudo unlink /etc/resolv.conf

echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

sudo usermod -aG docker $USER
newgrp docker

sudo systemctl start docker && sudo systemctl enable docker

sudo mkdir /pda-mysql
sudo chmod 777 /pda-mysql

#sudo setenforce 0
#sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

echo ==== Starto i container =======================================
docker run --detach --name mariadb \
  -e MYSQL_ALLOW_EMPTY_PASSWORD=yes \
  -e MYSQL_DATABASE=pdns \
  -e MYSQL_USER=pdns \
  -e MYSQL_PASSWORD=mypdns \
  -v /pda-mysql:/var/lib/mysql \
  mariadb:latest
	  
docker run -d -p 53:53 -p 53:53/udp --name pdns-master \
 --hostname pdns\
 --domainname dns.locale.com \
 --link mariadb:mysql \
  -e PDNS_master=yes \
  -e PDNS_api=yes \
  -e PDNS_api_key=secret \
  -e PDNS_webserver=yes \
  -e PDNS_webserver-allow-from=127.0.0.1,10.0.0.0/8,172.0.0.0/8,192.0.0.0/24 \
  -e PDNS_webserver_address=0.0.0.0 \
  -e PDNS_webserver_password=secret2 \
  -e PDNS_version_string=anonymous \
  -e PDNS_default_ttl=1500 \
  -e PDNS_allow_notify_from=0.0.0.0 \
  -e PDNS_allow_axfr_ips=127.0.0.1 \
  pschiffe/pdns-mysql
  
docker run -d --name pdns-admin-uwsgi \
  -p 9494:9494 \
  --link mariadb:mysql --link pdns-master:pdns \
  pschiffe/pdns-admin-uwsgi
  
docker run -d -p 8090:80 --name pdns-admin-static \
  --link pdns-admin-uwsgi:pdns-admin-uwsgi \
  pschiffe/pdns-admin-static