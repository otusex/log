Vagrant.configure("2") do |config|

    config.vm.define "web" do |web|
    web.vm.box = "centos/7"
    web.vm.network "private_network", ip: "192.168.10.22"
    web.vm.hostname = "web"
    web.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["modifyvm", :id, "--cpus", "2"]

      end

   config.vm.provision "shell", path: "wdo.sh"

end

    config.vm.define "log" do |log|
      log.vm.box = "centos/7"
      log.vm.network "private_network", ip: "192.168.10.23"
      log.vm.hostname = "log"
      log.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["modifyvm", :id, "--cpus", "2"]

      end

     config.vm.provision "shell", path: "ldo.sh"
     
    end

    config.vm.define "elk" do |elk|
    elk.vm.box = "centos/7"
    elk.vm.network "private_network", ip: "192.168.10.24"
    elk.vm.hostname = "elk"
    elk.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "2048"]
      vb.customize ["modifyvm", :id, "--cpus", "4"]
      end
    config.vm.provision "shell", path: "edo.sh"

 end

end
