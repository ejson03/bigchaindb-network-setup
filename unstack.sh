#!/usr/bin/env bash
# Copyright BigchainDB GmbH and BigchainDB contributors
# SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
# Code is Apache-2.0 and docs are CC-BY-4.0


set -o nounset

# Make sure umask is sane
umask 022

# defaults
stack_branch=${STACK_BRANCH:="master"}
stack_repo=${STACK_REPO:="bigchaindb/bigchaindb"}
stack_size=${STACK_SIZE:=4}
stack_type=${STACK_TYPE:="local"}
stack_type_provider=${STACK_TYPE_PROVIDER:=""}
tm_version=${TM_VERSION:="0.31.5"}
mongo_version=${MONGO_VERSION:="3.6"}
stack_vm_memory=${STACK_VM_MEMORY:=512}
stack_vm_cpus=${STACK_VM_CPUS:=1}
stack_box_name=${STACK_BOX_NAME:="bento/ubuntu-18.04"}
ssh_private_key_path=${SSH_PRIVATE_KEY_PATH:=""}
unstack_type=${UNSTACK_TYPE:="soft"}


# Check for uninitialized variables
NOUNSET=${NOUNSET:-}
if [[ -n "$NOUNSET" ]]; then
	set -o nounset
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
SCRIPTS_DIR=$TOP_DIR/bigchaindb/pkg/scripts
CONF_DIR=$TOP_DIR/bigchaindb/pkg/configuration

echo "Installation started at $(date '+%Y-%m-%d %H:%M:%S')"

function finish() {
	echo "Installation finished at $(date '+%Y-%m-%d %H:%M:%S')"
}
trap finish EXIT

export STACK_REPO=$stack_repo
export STACK_BRANCH=$stack_branch
echo "Using bigchaindb repo: '$STACK_REPO'"
echo "Using bigchaindb branch '$STACK_BRANCH'"

git clone https://github.com/${stack_repo}.git -b ${stack_branch} || true

# Source utility functions
source ${SCRIPTS_DIR}/functions-common

if [[ $stack_type == "local" ]]; then
	mongo_version=$(echo "$mongo_version" | cut -d. -f-2)
fi

# configure stack-config.yml
cat >$TOP_DIR/bigchaindb/pkg/configuration/vars/stack-config.yml <<EOF
---
stack_type: "${stack_type}"
stack_size: "${stack_size}"
stack_type_provider: "${stack_type_provider}"
stack_box_name: "${stack_box_name}"
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
  if [[ $unstack_type == "hard" ]]; then
    vagrant destroy -f
  elif [[ $unstack_type == "soft" ]]; then
    ansible-playbook $CONF_DIR/bigchaindb-stop.yml -i $CONF_DIR/hosts/all \
      --extra-vars "operation=stop home_path=${TOP_DIR}"
  fi
elif [[ $stack_type == "docker" ]]; then
  echo "Configuring Dockers locally!"
  source $SCRIPTS_DIR/bootstrap.sh --operation install
  cat > $CONF_DIR/hosts/all << EOF
  $(hostname)  ansible_connection=local
EOF

  ansible-playbook $CONF_DIR/bigchaindb-stop.yml -i $CONF_DIR/hosts/all \
    --extra-vars "operation=stop home_path=${TOP_DIR}"
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

echo -e "Finished unstacking!!"
set -o errexit
