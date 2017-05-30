VAGRANTFILE_API_VERSION = "2"

ahbase = "7.3.5"   # Base image version.  This is used to define the ahconfig.vm.box version!

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

# Ensure "containerized" is set to true in the following conditions,
# overriding user specification:
# * ahbase is 7.3.x
# * ahversion is 7.3.x
# * upgrade is true

if not containerized
  if ahversion and ahversion.start_with?("7.3")
    puts "ahversion is set to \"#{ahversion}\".  No RPMS available in 7.3.x.  Deploying with containerized kubernetes."
    containerized = true
  elsif ahbase.start_with?("7.3")
    puts "ahbase is set to \"#{ahbase}\".  No RPMS available in 7.3.x.  Deploying with containerized kubernetes."
    containerized = true
  elsif upgrade and not ahversion
    puts "Upgrade is \"true\".  No RPMS available in 7.3.x.  Deploying with containerized kubernetes."
    containerized = true
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
      ahconfig.vm.box = "atomic-#{ahbase}"
      ahconfig.vm.hostname = ahvm[:name].to_s
      ahconfig.vm.synced_folder ".", "/vagrant", disabled: true
      if Vagrant.has_plugin?('vagrant-registration')
        ahconfig.registration.username = ENV['rh_user']
        ahconfig.registration.password = ENV['rh_pass']
        if ENV['rh_poolid'] and not ENV['rh_poolid'].empty?
          ahconfig.registration.pools = ENV['rh_poolid']
        end
      end
      config.vm.provider :libvirt do |libvirt|
        libvirt.memory = 4096
        libvirt.cpus = 4
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
      else
        # In the event no upgrade is being performed, ensure the correct kube
        # container version is specified for ahbase.
        if ahbase.start_with?("7.3")
          kversion = "latest"
        else
          kversion = "1.2.0"
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
