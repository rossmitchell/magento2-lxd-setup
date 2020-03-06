Magento 2 cluster setup
=======================

Current Status
--------------

At the moment, this will setup a basic Magento 2 install, with out varnish or SSL termination. Those are still to be 
done and will be added soon. In the meantime this does the following

This is a way of setting up a clustered instance of Magento 2. It will install and configure the following machines

 * A load balancer to handle incoming requests
 * A Varnish instance
 * A Redis instance
 * A RabitMQ instance
 * An Elastic Search instance
 * A MySQL instance
 * A web server with Magento 2 installed

The instances are created using LXD, and then provisioned using Ansible.

This is largely used for my own development and testing, and as such should not be considered secure or production
ready

Installation
------------

Assuming the you already have LXD and Ansible installed, then you need to run the following tasks

### Install the Ansible roles

There are a huge number of well put together and tested roles for Ansible to install and configure software. I
saw no point in reinventing the wheel, so have made heavy use of them.

Run the following:

```bash
ansible-galaxy install -r requirements.yaml
```

### Update the LXD options

I would have loved to have used something pre-existing to handle creating the LXC machines, however I'm running
a cluster locally and needed the machines to end up on specific targets. The different options that I looked at
didn't appear to offer this out of the box, so I've added a basic shell script to handle this.

This is done in the [lxdUp](./lxdUp.bash) file. The variables that you may want to change are at the top of the
file, notable the target that the machines will be created on.

### Create the machines

Once you are happy with the options, run the following

```bash
./lxdUp.bash up
```

The machines will be created and an Ansible hosts file will be created based on the names each of them have.

### Update Ansible variables

#### Composer variables

In order to install Magento composer needs to know your authentication details to the repo. To set this up locally I'm 
using vaulted variables, these will need to be set up locally after the repo is cloned.

First create a secure password (I recommend something like a [diceware generator](https://www.rempe.us/diceware/#eff)) 
and save it to the `vault.password` file

The create a vaulted file using the following command `ansible-vault create environment/lxd/group_vars/web/vault.yaml`
and add the following variables to it:

 * vault_composer_magento_username
 * vault_composer_magento_password
 
#### Other Passwords

All other passwords used in the system are considered disposable and are generated the first time that they are needed.
You can find them in the `environment/lxd/one-time-passwords/` directory after the playbooks have finished.

#### Other values

There are various other variables that are currently using default values as this is developed. Once this is fully 
working, these need to be moved into a described locations so they can be updated.  

### Provision the machines

Run the following command

```bash
ansible-playbook ./playbooks/playbook-setup-environment.yaml
```

And then go and grab a coffee, this takes a bit of time to complete. Assuming there are no errors in the rn through, 
after 10 / 15 min you should have a fully functioning Magento 2 site up and running 

### Rerunning playbooks

The project has been split up to allow the different parts of it to be run in isolation, mainly to help with the 
development of the different parts of it. As such it should be possible to run any playbook in the 
[playbooks](./playbooks) (Top level playbooks), or [plays](./plays) (Individual components) on their own.

However many of these require information about other containers that the playbook is not running on in order to 
function. This is not a problem when running the top level playbooks, as they are set to run on all machines, however 
the component playbooks are restricted to run on individual containers / groups.

To get around this we are [fact caching](https://docs.ansible.com/ansible/latest/plugins/cache.html) capabilities of 
Ansible, and this is configured in the [ansible.cfg](./ansible.cfg) file. However there are two things to be aware of

 * First, the cache has a lifetime of 24 hours. If you haven't rerun a playbook in the last 24hours you will need to 
 regenerate the cache
 * Secondly, if you drop and recreate a container, then you will need to manually refresh the cache
 
The easiest way to do this is to delete the invalid files in the `facts/` directory and then run the debugging playbook

```bash
ansible-playbook ./playbooks/playbook-debug.yaml
```                                             

This connects to each machine and echos "Hello World", and is the quickest way I have of regenerating the cache. It is
also useful to make sure that everything is setup correctly and you can connect to each of the machines that is expected
to be there
