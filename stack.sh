#!/usr/bin/env bash
# Copyright BigchainDB GmbH and BigchainDB contributors
# SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
# Code is Apache-2.0 and docs are CC-BY-4.0

set -o nounset

# Make sure umask is sane
umask 022

# defaults
stack_size=${STACK_SIZE:=4}
stack_type=${STACK_TYPE:="local"}
stack_box_name=${STACK_BOX_NAME="bento/ubuntu-18.04"}
stack_type_provider=${STACK_TYPE_PROVIDER:=""}
tm_version=${TM_VERSION:="0.31.5"}
mongo_version=${MONGO_VERSION:="3.6"}
stack_vm_memory=${STACK_VM_MEMORY:=512}
stack_vm_cpus=${STACK_VM_CPUS:=1}
ssh_private_key_path=${SSH_PRIVATE_KEY_PATH:=""}


# Check for uninitialized variables
NOUNSET=${NOUNSET:-}
if [[ -n "$NOUNSET" ]]; then
	set -o nounset
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
echo "Top directory $TOP_DIR"
SCRIPTS_DIR=$TOP_DIR/scripts
CONF_DIR=$TOP_DIR/configuration

echo "Installation started at $(date '+%Y-%m-%d %H:%M:%S')"

function finish() {
	echo "Installation finished at $(date '+%Y-%m-%d %H:%M:%S')"
}
trap finish EXIT

# Source utility functions
source ${SCRIPTS_DIR}/functions-common

if [[ $stack_type == "local" ]]; then
	mongo_version=$(echo "$mongo_version" | cut -d. -f-2)
fi

# configure stack-config.yml
cat >$CONF_DIR/vars/stack-config.yml <<EOF
---
stack_type: "${stack_type}"
stack_size: "${stack_size}"
stack_box_name: "${stack_box_name}"
stack_type_provider: "${stack_type_provider}"
stack_vm_memory: "${stack_vm_memory}"
stack_vm_cpus: "${stack_vm_cpus}"
tm_version: "${tm_version}"
mongo_version: "${mongo_version}"
ssh_private_key_path: "${ssh_private_key_path}"
EOF

#Convert to lowercase
stack_type="$(echo $stack_type | tr '[A-Z]' '[a-z]')"
stack_type_provider="$(echo $stack_type_provider | tr '[A-Z]' '[a-z]')"

if [[ $stack_type == "local" ]]; then
	echo "Configuring setup locally!"
	vagrant up --provider virtualbox --provision
	ansible-playbook $CONF_DIR/bigchaindb-start.yml \
		-i $CONF_DIR/hosts/all \
		--extra-vars "operation=start home_path=${TOP_DIR}"
elif [[ $stack_type == "docker" ]]; then
	echo "Configuring Dockers locally!"
	source $SCRIPTS_DIR/bootstrap.sh --operation install
	cat >$CONF_DIR/hosts/all <<EOF
  $(hostname)  ansible_connection=local
EOF
	ansible-playbook $CONF_DIR/bigchaindb-start.yml \
    -i $CONF_DIR/hosts/all \
	--extra-vars "home_path=${TOP_DIR}"

else
	echo "Invalid Stack Type OR Provider"
	exit 1
fi

# Kill background processes on exit
trap exit_trap EXIT
function exit_trap {
    exit $?
}
# Exit on any errors so that errors don't compound and kill if any services already started
trap err_trap ERR
function err_trap {
    local r=$?
    tmux kill-session bdb-dev
    set +o xtrace
    exit $?
}

echo -e "Finished stacking!"
set -o errexit
