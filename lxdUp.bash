#!/usr/bin/env bash
readonly DIR=$(dirname $(readlink -f "$0"))
# LXC Vars
prefix="magento2-demo";
defaultImage="centos/8";
target="--target=baby"
machines=('load-balancer' 'varnish' 'web' 'database' 'rabbit' 'redis' 'elastic-search')
declare -A customImages
customImages["varnish"]="centos/7" # Need to use 7 to handle dependency issues around pygpgme

# Ansiable Groups
baseMachineGroup=();
loadBalancerGroup=();
varnishGroup=();
webGroup=();
databaseGroup=();
rabbitGroup=();
redisGroup=();
elasticGroup=();

# Ansible Hosts file
ansibleHostFile="${DIR}/environment/lxd/hosts"

action=${1:-unknown}

function createMachine() {
    machineName=$1;
    name=$2;
    if test "${customImages[${name}]+isset}"
    then
        image=${customImages[${name}]}
    else
        image=${defaultImage};
    fi
    echo "
Going to create and bring up $machineName
=========================================";
    if ! lxc info "${machineName}" &> /dev/null
    then
      set -x
      lxc launch images:${image} "${machineName}" "${target}"
      set +x
    fi
    lxc start "${machineName}" &> /dev/null || true
    echo "
${machineName} should be up and running
---------------------------------------
"
}

function deleteMachine() {
    machineName=$1
    echo "Going to delete $machineName";
    lxc stop "${machineName}" &> /dev/null || true
    lxc delete "${machineName}"
}

function addToGroup() {
    machineName=$1;
    baseMachineGroup+=("${machineName}");
    case ${machineName} in
    *load-balancer*)
      loadBalancerGroup+=("${machineName}");
      ;;
    *varnish*)
      varnishGroup+=("${machineName}");
      ;;
    *web*)
      webGroup+=("${machineName}");
      ;;
    *database*)
      databaseGroup+=("${machineName}");
      ;;
    *rabbit*)
      rabbitGroup+=("${machineName}");
      ;;
    *redis*)
      redisGroup+=("${machineName}");
      ;;
    *elastic-search*)
      elasticGroup+=("${machineName}");
      ;;
    *)
      echo "Unknown machine group of ${machineName} - Update the script";
      exit 5;
    esac
}

function createAnsibleGroup() {
  all_args=("$@")
  groupName=$1;
  rest_args=("${all_args[@]:1}")
  echo "[${groupName}]";
  for m in "${rest_args[@]}"
  do
    echo ${m}
  done
  echo ""
}

function createHostFile() {
  createAnsibleGroup base_machines "${baseMachineGroup[@]}"
  createAnsibleGroup load_balancers "${loadBalancerGroup[@]}"
  createAnsibleGroup varnish "${varnishGroup[@]}"
  createAnsibleGroup web "${webGroup[@]}"
  createAnsibleGroup database "${databaseGroup[@]}"
  createAnsibleGroup rabbit "${rabbitGroup[@]}"
  createAnsibleGroup redis "${redisGroup[@]}"
  createAnsibleGroup elastic "${elasticGroup[@]}"
}

function displayHelp() {
       title=$1;
           echo "
$title
Call the script in one of the following ways:

    * $0 up         - to create and start the machines
    * $0 all-down   - to destroy all the machines
    * $0 down       - to destroy a named machine
    * $0 help       - to show this message
";
}

fullName="${prefix}-${name}";
case ${action} in
  'up')

    for name in "${machines[@]}"
    do
    createMachine "${fullName}" "${name}";
    addToGroup "${fullName}";
    createHostFile > "${ansibleHostFile}"
    done
    ;;
  'all-down')
    for name in "${machines[@]}"
    do
        deleteMachine "${fullName}"
    done
    ;;
  'down')
    deleteMachine "${fullName}"
    ;;
  'help')
    displayHelp "
Help
====
";
    exit 0;
    ;;
  *)
    displayHelp "
Unknown action!
===============
    ";
    exit 10;
    ;;
esac


