VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  machines = [ {:name => 'owl', :primary => true},
               {:name => 'tigger', :primary => false},
               {:name => 'pooh', :primary => false},
             ]
  groups = {}
  groups["master"] = []
  groups["nodes"] = []
  machines.each do |machine|
    if machine[:primary]
      groups["master"].push(machine[:name])
    else
      groups["nodes"].push(machine[:name])
    end
  end

  last = machines[-1][:name]
  machines.each do |ahvm|
    config.vm.define ahvm[:name].to_s, primary: ahvm[:primary] do |ahconfig|
      ahconfig.vm.box = "atomic-7.2.5" 
      ahconfig.vm.hostname = ahvm[:name].to_s
      ahconfig.vm.synced_folder ".", "/vagrant", disabled: true
      # ahconfig.vm.provider :libvirt do |libvirt|
      #   libvirt.storage_pool_name = "virtstorage"
      # end
      #ahconfig.vm.provision "shell", path: "scripts/kube-config.sh", args: params[:args].to_s
      if Vagrant.has_plugin?('vagrant-registration')
        ahconfig.registration.username = ENV['rh_user']
        ahconfig.registration.password = ENV['rh_pass']
      end
      ahconfig.vm.provision "shell", path: "scripts/ah_upgrade.sh"
      ahconfig.vm.provision :reload
      if ahvm[:name] == last
        ahconfig.vm.provision :ansible do |ansible|
          ansible.limit = "all"
          ansible.playbook = 'playbook.yaml'
          ansible.groups = groups
        end
      end
    end
  end
end
