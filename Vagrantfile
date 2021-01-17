Vagrant.configure("2") do |config|

    config.vm.define "web" do |web|

    web.vm.box = "centos/7"

    web.vm.network "private_network", ip: "192.168.10.22"

    web.vm.hostname = "web"

    web.vm.provider :virtualbox do |vb|

      vb.customize ["modifyvm", :id, "--memory", "512"]

      vb.customize ["modifyvm", :id, "--cpus", "2"]

      end

    web.vm.provision "shell", inline: <<-SHELL

       mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh

       sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

       systemctl restart sshd

       timedatectl set-timezone Europe/Moscow

       yum install epel-release -y

       yum check-update

       yum install ntp -y && systemctl start ntpd && systemctl enable ntpd

       yum install audit audispd-plugins policycoreutils-python nginx -y

    SHELL

    web.vm.provision "file", source: "./files/web-nginx.conf", destination: "/tmp/nginx.conf"

    web.vm.provision "file", source: "./files/web-rsyslog.conf", destination: "/tmp/rsyslog.conf"

    web.vm.provision "file", source: "./files/web-audit.rules", destination: "/tmp/audit.rules"

    web.vm.provision "file", source: "./files/web-audisp-remote.conf", destination: "/tmp/audisp-remote.conf"

    web.vm.provision "file", source: "./files/web-au-remote.conf", destination: "/tmp/au-remote.conf"

    web.vm.provision "file", source: "./files/web-auditd.conf", destination: "/tmp/auditd.conf"

    web.vm.provision "shell", inline: <<-SHELL

    mv /tmp/nginx.conf /etc/nginx/nginx.conf

    mv /tmp/rsyslog.conf /etc/rsyslog.conf

    mv /tmp/audit.rules /etc/audit/rules.d/audit.rules

    mv /tmp/audisp-remote.conf /etc/audisp/audisp-remote.conf

    mv /tmp/au-remote.conf /etc/audisp/plugins.d/au-remote.conf

    mv /tmp/auditd.conf /etc/audit/auditd.conf

    sudo chown root:root /etc/audit/auditd.conf; sudo chmod 640 /etc/audit/auditd.conf; 
    
    sudo chown root:root /etc/nginx/nginx.conf; sudo chmod 644 /etc/nginx/nginx.conf;

    sudo chown root:root /etc/rsyslog.conf; sudo chmod 644 /etc/rsyslog.conf; 
    
    sudo chown root:root /etc/audit/rules.d/audit.rules; sudo chmod 644 /etc/audit/rules.d/audit.rules;

    sudo chown root:root /etc/audisp/audisp-remote.conf; sudo chmod 644 /etc/audisp/audisp-remote.conf; 
    
    sudo chown root:root /etc/audisp/plugins.d/au-remote.conf; sudo chmod 644 /etc/audisp/plugins.d/au-remote.conf; 

    systemctl enable nginx; systemctl start nginx; systemctl restart rsyslog; service auditd restart; systemctl daemon-reload
    
    SHELL

    end

    config.vm.define "log" do |log|

      log.vm.box = "centos/7"

      log.vm.network "private_network", ip: "192.168.10.23"

      log.vm.hostname = "log"

      log.vm.provider :virtualbox do |vb|

      vb.customize ["modifyvm", :id, "--memory", "512"]

      vb.customize ["modifyvm", :id, "--cpus", "2"]

      end


      log.vm.provision "shell", inline: <<-SHELL

       mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh

       sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

       systemctl restart sshd

       timedatectl set-timezone Europe/Moscow

       yum install epel-release -y

       yum check-update
       
       yum install ntp -y && systemctl start ntpd && systemctl enable ntpd

       yum install audit audispd-plugins policycoreutils-python firewalld -y; systemctl enable firewalld && sudo systemctl start firewalld

    SHELL

       log.vm.provision "file", source: "./files/log-auditd.conf", destination: "/tmp/auditd.conf"

       log.vm.provision "file", source: "./files/log-rsyslog.conf", destination: "/tmp/rsyslog.conf"

       log.vm.provision "shell", inline: <<-SHELL

       mv /tmp/auditd.conf /etc/audit/auditd.conf

       mv /tmp/rsyslog.conf /etc/rsyslog.conf

       sudo chown root:root /etc/audit/auditd.conf; sudo chmod 640 /etc/audit/auditd.conf; 

       sudo chown root:root /etc/rsyslog.conf; sudo chmod 644 /etc/rsyslog.conf;

       sudo mkdir -p /mnt/logging/192.168.10.22

       sudo semanage fcontext -a -t var_log_t '/mnt/logging/192.168.10.22(/.*)?'

       sudo restorecon -Rv /mnt/logging/192.168.10.22/

       sudo firewall-cmd --permanent --add-port=514/udp; sudo firewall-cmd --permanent --add-port=514/tcp

       sudo firewall-cmd --permanent --add-port=60/udp; sudo firewall-cmd --permanent --add-port=60/tcp; sudo firewall-cmd --reload

       systemctl restart rsyslog; service auditd restart; systemctl daemon-reload

    SHELL

  end

   config.vm.define "elk" do |elk|

    elk.vm.box = "centos/7"

    elk.vm.network "private_network", ip: "192.168.10.24"

    elk.vm.hostname = "elk"

    elk.vm.provider :virtualbox do |vb|

      vb.customize ["modifyvm", :id, "--memory", "2048"]

      vb.customize ["modifyvm", :id, "--cpus", "4"]

      end

    elk.vm.provision "shell", inline: <<-SHELL

       mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh

       sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

       systemctl restart sshd

       timedatectl set-timezone Europe/Moscow

       yum install epel-release -y

       sudo setenforce 0; sudo sed -i 's/=enforcing/=disabled/g' /etc/selinux/config

       sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

       # Создание файла оф. репозитория
       cat <<-'EOF' > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
       # Установка компонентов
       sudo yum check-update; sudo yum install ntp -y && systemctl start ntpd && systemctl enable ntpd

       sudo yum -y install java-openjdk-devel java-openjdk nano firewalld audit audispd-plugins policycoreutils-python; sudo systemctl enable firewalld && sudo systemctl start firewalld

       # Создание папки для хранения логов с машины которая их генерирует (192.168.10.22)
       sudo mkdir -p /mnt/logging/192.168.10.22; sudo semanage fcontext -a -t var_log_t '/mnt/logging/192.168.10.22(/.*)?'; sudo restorecon -Rv /mnt/logging/192.168.10.22/

       # Установка правил файервола для доступа к rsyslog и kibana извне
       sudo firewall-cmd --permanent --add-port=514/udp; sudo firewall-cmd --permanent --add-port=514/tcp; sudo firewall-cmd --permanent --add-port=5601/tcp; sudo firewall-cmd --reload
       
       # Установка компонентов основного стека логирования
       sudo yum install --enablerepo=elasticsearch-7.x elasticsearch kibana filebeat -y; sudo filebeat modules enable nginx


    SHELL

    elk.vm.provision "file", source: "./files/elk-rsyslog.conf", destination: "/tmp/rsyslog.conf"

    elk.vm.provision "shell", path: "./files/sed.sh"

    elk.vm.provision "shell", inline: <<-SHELL

    mv /tmp/rsyslog.conf /etc/rsyslog.conf

    sudo chown root:root /etc/rsyslog.conf; sudo chmod 644 /etc/rsyslog.conf

    sudo systemctl daemon-reload; sudo systemctl enable elasticsearch; sudo systemctl enable filebeat; sudo systemctl enable kibana;

    sudo systemctl start elasticsearch; sudo systemctl start filebeat; sudo systemctl start kibana;

    sleep 60

    # Импортируем индекс для kibana (необязательно)
    sudo curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@/vagrant/files/export.ndjson

    sudo reboot

    SHELL

    end

end