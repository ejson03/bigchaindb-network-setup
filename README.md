### Bigchain Network Configuration

Complete steup for generating a BigchainDB network

## Progress

- [x] Install mongodb
- [x] Install tendermint
- [x] Install bigchaindb
- [x] Tendermint P2P setup
- [ ] Sort bigchain connection issue
- [ ] Sort validator issue

## Steps to proceed

Setup Vagrant & Ansible
```
bash stack.sh
```

Setup only Ansible
```
ansible-playbook configuration/bigchaindb-start.yml -i configuration/hosts/all --extra-vars "operation=start home_path=$(pwd)"
```

WSL Essential Commands for Vagrant Setup with VirtualBox backend
```
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="<path-to-Vagrantfile"
export PATH="$PATH:<path-to-oracle>/Oracle/VirtualBox"
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
```



