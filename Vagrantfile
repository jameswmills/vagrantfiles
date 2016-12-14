VAGRANTFILE_API_VERSION = "2"

###DEFAULTS###

kversion = "1.2.0" # Default image version for containerized kubernetes
ahbase = "7.2.5"   # Base image version.  Change if  ahconfig.vm.box is not 7.2.5!


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

ahversion = nil
if ENV['AHVERSION'] and not ENV['AHVERSION'].empty?
  ahversion = ENV['AHVERSION']
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
        if ahbase.start_with?("7.2") and ahbase != "7.2.7"
          if (not ahversion) or ahversion.start_with?("7.3")
            # Bug when moving from < 7.2.7 to 7.3.x
            ahconfig.vm.provision "shell", path: "scripts/ah_get_72x_to_727.sh"
            ahconfig.vm.provision :reload
          end
        end
        if ahversion
          if ahversion.start_with?("7.3")
            kversion = "latest"
          end
          ahconfig.vm.provision "shell", path: "scripts/ah_upgrade.sh", args: [ahversion]
        else
          kversion = "latest"
          ahconfig.vm.provision "shell", path: "scripts/ah_upgrade.sh"
        end
      end
      # We still want the reboot here, even if we are not upgrading,
      # to work around weird libvirt DNS issues...
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
          ansible.extra_vars = {
            kversion: kversion
          }
        end
      end
    end
  end
end
