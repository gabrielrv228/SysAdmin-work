Vagrant.configure("2") do |config|
  config.vm.define "elasticsearch" do |elasticsearch|
    elasticsearch.vm.provision "shell", path:"scripts/elastic.sh"
 
    elasticsearch.vm.box = "ubuntu/focal64"  
    elasticsearch.vm.hostname = "Stack"
    elasticsearch.vm.network "private_network", ip: "192.168.10.2" 
 
    elasticsearch.vm.provider "virtualbox" do |vb|
    elasticsearch.vm.network "forwarded_port", guest: 80, host: 8081, id: "Elastic"
    elasticsearch.vm.network "forwarded_port", guest: 9200, host: 9200, id: "Elasticc"
    file_to_disk1 = "elastic_vol.vmdk"
 
    unless File.exist?(file_to_disk1)
        vb.customize [ "createmedium", "disk", "--filename", "elastic_vol.vmdk", "--format", "vmdk", "--size", 4096 * 1 ]
    end
  
    vb.customize [ "storageattach", "elasticsearch" , "--storagectl", "SCSI", "--port", "2", "--device", "0", "--type", "hdd", "--medium", file_to_disk1]
    vb.name = "elasticsearch"
    vb.memory = "4072"
    vb.cpus = "2"
     
   end
 end  
 config.vm.define "wordpress" do |wordpress|
    wordpress.vm.provision "shell", path:"scripts/wp.sh"
   
      wordpress.vm.box = "ubuntu/focal64"  
      wordpress.vm.hostname = "Servicioweb"
      wordpress.vm.network "private_network", ip: "192.168.10.1" 
 
      wordpress.vm.provider "virtualbox" do |vb|
      wordpress.vm.network "forwarded_port", guest: 80, host: 8085, id: "Wordpress"
      file_to_disk1 = "database.vmdk"
 
      unless File.exist?(file_to_disk1)
          vb.customize [ "createmedium", "disk", "--filename", "database.vmdk", "--format", "vmdk", "--size", 4096 * 1 ]
      end
   
      vb.customize [ "storageattach", "wordpress" , "--storagectl", "SCSI", "--port", "2", "--device", "0", "--type", "hdd", "--medium", file_to_disk1]  
      vb.name = "wordpress"
      vb.memory = "1024"
      vb.cpus = "1"
     end
   end 
 end
