### Bigchain Network Configuration

Complete steup for generating a BigchainDB network


## Steps to proceed

Bootstrap System
```
cd pkg/scripts
bash bootstrap.sh --operation install
```

Local Ansible Setup
```
cd pkg/configuration/hosts
```

Edit all
```
# Delete any existing configuration in this file and insert
# Hostname of dev machine
<HOSTNAME> ansible_connection=local
```

Setup
```
cd pkg/configuration
ansible-playbook bigchaindb-start.yml -i hosts/all --extra-vars "operation=start home_path=$(pwd)"
```


