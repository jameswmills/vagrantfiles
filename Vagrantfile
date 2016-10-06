VAGRANTFILE_API_VERSION = "2"

containerized = true
if ENV['CONTAINERIZED']
  if ENV['CONTAINERIZED'].downcase == "false"
    containerized = false
  end
end

upgrade = true
if ENV['AHUPGRADE']
  if ENV['AHUPGRADE'].downcase == "false"
    upgrade = false
  end
end

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
      if Vagrant.has_plugin?('vagrant-registration')
        ahconfig.registration.username = ENV['rh_user']
        ahconfig.registration.password = ENV['rh_pass']
      end
      if upgrade
        ahconfig.vm.provision "shell", path: "scripts/ah_upgrade.sh"
      end
      ahconfig.vm.provision :reload
      if ahvm[:name] == last
        ahconfig.vm.provision :ansible do |ansible|
          ansible.limit = "all"
          if containerized
            ansible.playbook = 'containerized-playbook.yaml'
          else
            ansible.playbook = 'playbook.yaml'
          end
          ansible.groups = groups
        end
      end
    end
  end
end
