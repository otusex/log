#!/bin/bash


mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
timedatectl set-timezone Europe/Moscow
yum install epel-release -y
sudo setenforce 0; sudo sed -i 's/=enforcing/=disabled/g' /etc/selinux/config
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch


cat << EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo yum check-update
sudo yum install ntp -y 
systemctl start ntpd 
systemctl enable ntpd
sudo yum -y install java-openjdk-devel java-openjdk nano firewalld audit audispd-plugins policycoreutils-python
sudo systemctl enable firewalld 
sudo systemctl start firewalld
sudo mkdir -p /mnt/logging/192.168.10.22
sudo semanage fcontext -a -t var_log_t '/mnt/logging/192.168.10.22(/.*)?'
sudo restorecon -Rv /mnt/logging/192.168.10.22/
sudo firewall-cmd --permanent --add-port=514/udp
sudo firewall-cmd --permanent --add-port=514/tcp
sudo firewall-cmd --permanent --add-port=5601/tcp
sudo firewall-cmd --reload
sudo yum install --enablerepo=elasticsearch-7.x elasticsearch kibana filebeat -y
sudo filebeat modules enable nginx



sudo sed -i "0,/#var.paths:/{s/#var.paths:.*/var.paths: [\"\/mnt\/logging\/192.168.10.22\/192.168.10.22-nginx-access.log*\"]/}" /etc/filebeat/modules.d/nginx.yml
sudo sed -i "1,/#var.paths:/{s/#var.paths:.*/var.paths: [\"\/mnt\/logging\/192.168.10.22\/192.168.10.22-nginx-error.log*\"]/}" /etc/filebeat/modules.d/nginx.yml

sudo sed -i 's/#cluster.name:'.*'/cluster.name: elk/g' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#node.name:'.*'/node.name: elk/g' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#network.host:'.*'/network.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#cluster.initial_master_nodes:'.*'/cluster.initial_master_nodes: ["elk"]/g' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#http.port:'.*'/http.port: 9200/g' /etc/elasticsearch/elasticsearch.yml



sudo sed -i 's/#server.host:'.*'/server.host: 0.0.0.0/g' /etc/kibana/kibana.yml
sudo sed -i 's/#server.port:'.*'/server.port: 5601/g' /etc/kibana/kibana.yml
sudo sed -i 's/#elasticsearch.hosts:'.*'/elasticsearch.hosts: ["http:\/\/localhost:9200"] /g' /etc/kibana/kibana.yml


sudo chown root:root /etc/rsyslog.conf
sudo chmod 644 /etc/rsyslog.conf
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl enable filebeat
sudo systemctl enable kibana;
sudo systemctl start elasticsearch
sudo systemctl start filebeat
sudo systemctl start kibana
sleep 60


sudo curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@/vagrant/files/export.ndjson
sudo reboot



