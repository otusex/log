#!/usr/bin/env bash


# Настройка filebeat модуля nginx
sudo sed -i "0,/#var.paths:/{s/#var.paths:.*/var.paths: [\"\/mnt\/logging\/192.168.10.22\/192.168.10.22-nginx-access.log*\"]/}" /etc/filebeat/modules.d/nginx.yml

sudo sed -i "1,/#var.paths:/{s/#var.paths:.*/var.paths: [\"\/mnt\/logging\/192.168.10.22\/192.168.10.22-nginx-error.log*\"]/}" /etc/filebeat/modules.d/nginx.yml


# Настройка elasticsearch
sudo sed -i 's/#cluster.name:'.*'/cluster.name: elk/g' /etc/elasticsearch/elasticsearch.yml

sudo sed -i 's/#node.name:'.*'/node.name: elk/g' /etc/elasticsearch/elasticsearch.yml

sudo sed -i 's/#network.host:'.*'/network.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml

sudo sed -i 's/#cluster.initial_master_nodes:'.*'/cluster.initial_master_nodes: ["elk"]/g' /etc/elasticsearch/elasticsearch.yml

sudo sed -i 's/#http.port:'.*'/http.port: 9200/g' /etc/elasticsearch/elasticsearch.yml

#sudo sed -i 's/#bootstrap.memory_lock:'.*'/bootstrap.memory_lock: true/g' /etc/elasticsearch/elasticsearch.yml

#sudo sed -i 's/#MAX_LOCKED_MEMORY='.*'/MAX_LOCKED_MEMORY=unlimited/g' /etc/sysconfig/elasticsearch


# Настройка kibana

sudo sed -i 's/#server.host:'.*'/server.host: 0.0.0.0/g' /etc/kibana/kibana.yml

sudo sed -i 's/#server.port:'.*'/server.port: 5601/g' /etc/kibana/kibana.yml

sudo sed -i 's/#elasticsearch.hosts:'.*'/elasticsearch.hosts: ["http:\/\/localhost:9200"] /g' /etc/kibana/kibana.yml
