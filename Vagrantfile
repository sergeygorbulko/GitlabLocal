Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.boot_timeout = 1000
  
  # Используем Hyper-V как основной провайдер на Windows
  config.vm.provider "hyperv" do |hv|
    # Увеличиваем память до 8ГБ, чтобы GitLab не вешал систему при установке
    hv.memory = "8192"
    hv.maxmemory = "8192"
    hv.cpus = 2
    hv.vmname = "gitlab-server"
    hv.enable_virtualization_extensions = true
    # Фиксируем коммутатор External не используем (вызывает ошибку в некоторых сборках)
    # hv.virtual_switch = "External"
  end

  # Настройка сети: в Hyper-V для статического IP лучше использовать DHCP 
  # и настраивать статический адрес ВНУТРИ гостя скриптом (см. install-gitlab.sh),
  # так как параметр public_network часто не может корректно прокинуть IP на Windows.
  config.vm.network "public_network"

  # Синхронизация папок: rsync на Windows может требовать установки доп. ПО.
  # Если rsync не установлен, Vagrant предложит альтернативы (SMB).
  # config.vm.synced_folder ".", "/vagrant", type: "rsync"
  config.vm.synced_folder ".", "/vagrant", type: "smb"

  # Провижининг: установка и настройка
  config.vm.provision "shell", path: "install-gitlab.sh"
  config.vm.provision "shell", path: "configure-gitlab.sh"

  config.vm.hostname = "gitlab"
end
