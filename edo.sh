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

cat << EOF > /etc/rsyslog.conf
# rsyslog configuration file

# For more information see /usr/share/doc/rsyslog-*/rsyslog_conf.html
# If you experience problems, see http://www.rsyslog.com/doc/troubleshoot.html

#### MODULES ####

# The imjournal module bellow is now used as a message source instead of imuxsock.
$ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
$ModLoad imjournal # provides access to the systemd journal
#$ModLoad imklog # reads kernel messages (the same are read from journald)
#$ModLoad immark  # provides --MARK-- message capability

# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514


#### GLOBAL DIRECTIVES ####

# Where to place auxiliary files
$WorkDirectory /var/lib/rsyslog

# Use default timestamp format
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

# File syncing capability is disabled by default. This feature is usually not required,
# not useful and an extreme performance hit
#$ActionFileEnableSync on

# Include all config files in /etc/rsyslog.d/
$IncludeConfig /etc/rsyslog.d/*.conf

# Turn off message reception via local log socket;
# local messages are retrieved through imjournal now.
$OmitLocalLogging on

# File to store the position in the journal
$IMJournalStateFile imjournal.state


#### RULES ####
template(name="OnlyMsg" type="string" string="%msg:2:$:%\n")
if $fromhost-ip == "192.168.10.22"  and $syslogtag == 'nginx_access:' then {
	action(type="omfile" file="/mnt/logging/192.168.10.22/192.168.10.22-nginx-access.log" template="OnlyMsg")
	stop
}
if $fromhost-ip == "192.168.10.22"  and $syslogtag == 'nginx_error:' then {
	action(type="omfile" file="/mnt/logging/192.168.10.22/192.168.10.22-nginx-error.log" template="OnlyMsg")
	stop
}

# Log all kernel messages to the console.
# Logging much else clutters up the screen.
#kern.*                                                 /dev/console

# Log anything (except mail) of level info or higher.
# Don't log private authentication messages!
*.info;mail.none;authpriv.none;cron.none                /var/log/messages

# The authpriv file has restricted access.
authpriv.*                                              /var/log/secure

# Log all the mail messages in one place.
mail.*                                                  -/var/log/maillog


# Log cron stuff
cron.*                                                  /var/log/cron

# Everybody gets emergency messages
*.emerg                                                 :omusrmsg:*

# Save news errors of level crit and higher in a special file.
uucp,news.crit                                          /var/log/spooler

# Save boot messages also to boot.log
local7.*                                                /var/log/boot.log


# ### begin forwarding rule ###
# The statement between the begin ... end define a SINGLE forwarding
# rule. They belong together, do NOT split them. If you create multiple
# forwarding rules, duplicate the whole block!
# Remote Logging (we use TCP for reliable delivery)
#
# An on-disk queue is created for this action. If the remote host is
# down, messages are spooled to disk and sent when it is up again.
#$ActionQueueFileName fwdRule1 # unique name prefix for spool files
#$ActionQueueMaxDiskSpace 1g   # 1gb space limit (use as much as possible)
#$ActionQueueSaveOnShutdown on # save messages to disk on shutdown
#$ActionQueueType LinkedList   # run asynchronously
#$ActionResumeRetryCount -1    # infinite retries if host is down
# remote host is: name/ip:port, e.g. 192.168.0.1:514, port optional
#*.* @@remote-host:514
# ### end of the forwarding rule ###
EOF


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



