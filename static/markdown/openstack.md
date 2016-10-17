# Deploy OpenStack

The lab environment is accessed via the terminal screen embedded below.  To
find it, simply scroll down.

## Overview

The lab environment consists of five virtual machines, accessible via the
following local IP addresses.

* _deploy_: **`192.168.122.100`**
* _alice_: **`192.168.122.111`**
* _bob_: **`192.168.122.112`**
* _charlie_: **`192.168.122.113`**
* _daisy_: **`192.168.122.114`**

The _deploy_ node  has a publicly available IP address.
Your terminal automatically connects to _deploy_.

When you connect to _deploy_, you automatically enter a `screen` session.
`screen` is a terminal multiplexer that, among other things, allows you
reconnect to a previous session.  This means that if you close the browser page
and return to the exercise later on, your session, including scrollback and
command history, will be exactly as you left it.

## SSH Between Nodes

You can use SSH from _deploy_ to hop to the other nodes.  To connect to
_alice_, follow these instructions using the terminal below:

1. From the _deploy_ node (it's where you start out), SSH into _alice_ by
   entering:

        $ sudo -i
        # ssh alice

2. To confirm the authenticity of the host, enter "yes" at the prompt.

3. Type the following to return to `deploy`:

        # exit

4. Repeat steps 1 to 3 for each of the other nodes, `bob`, `charlie`, and
   `daisy`.

> Note: Whenever specific instructions are given as the ones above, do your
> best to execute them as stated.  You will be graded on the results.


## Configuration files.

The *`/etc/openstack_deploy/openstack_user_config.yml`* describes the layout for this environment.
The *`/etc/openstack_deploy/user_variables.yml`* file defines the global overrides for the default variables
The *`/etc/openstack_deploy/user_secrets.yml`* file contains service credentials for all services.


## Bootstrapping OpenStack Ansible

The `deploy` node contains a checkout of the OSA repository, which you'll use
to deploy OpenStack, in `/home/training/openstack-ansible`.  To install all
prerequisites for running the OSA playbooks therein (including Ansible
itself!), you must run the provided `bootstrap-ansible.sh` script.  On the
terminal screen, execute it as follows:

1. Change to the repository directory:

        $ cd ~/openstack-ansible

2. Execute the script:

        $ sudo scripts/bootstrap-ansible.sh

This will take a few minutes.  Once the execution is complete you should see
output like this:

    openstack-ansible script created.
    System is bootstrapped and ready for use.

This means that in addition to Ansible's own `ansible-playbook` program, the
bootstrap script installed an `openstack-ansible` command.  The latter, which
you'll be using throughout these labs, wraps `ansible-playbook`.  It makes the
various configuration files available to the OSA playbooks without the need for
unwieldy command line switches.

## Preparing target hosts

Before you can deploying actual services, you must use OSA to prepare the nodes
onto which you wish to deploy them.  To that end, OSA provides the
`setup-hosts.yml` playbook.  This playbook will build the required LXC
containers on the target hosts, and install common components into them.

Before running it, however, take a quick look at how it's configured:

    $ less /etc/openstack_deploy/openstack_user_config.yml

Scroll down and find the following stanza:

    shared-infra_hosts:
      alice:
        affinity:
          galera_container: 1
          rabbit_mq_container: 1
        ip: 172.29.236.10

Like all the `*_hosts` stanzas that follow, this is how you tell OSA about your
pre-existing hardware, and how you want it used.  `shared-infra_hosts` lists
hosts on which to deploy shared infrastructure services such as Galera and
RabbitMQ. In this specific example, the `setup-hosts.yml` playbook can tell
from the configuration that it'll have to create six LXC containers on the
`alice` VM.

To execute the playbook and set up all hosts (including `alice`, `bob`,
`charlie`, and `daisy`), run the following commands in order:

> Note: For security, your terminal connects to the lab environment as the
> `training` user.  However, OSA requires playbooks to be run as the `root`
> user; just `sudo` is not supported.  From this point on, whenever you
> encounter command instructions preceded by the '#' character, you must
> execute them as `root`.

1. Change to the OSA playbooks directory:

        $ cd ~/openstack-ansible/playbooks

2. Become root:

        $ sudo su

3. Run the host setup playbook using the `openstack-ansible` command:

        # openstack-ansible setup-hosts.yml

If everything goes well, you should see a *PLAY RECAP* with several successful
items, one for each of `alice`, `bob`, `charlie`, and `daisy`, as well as one
for each of the containers that was created.

## Deploying OpenStack infrastructure services

Once the target hosts are ready, you'll deploy the services OpenStack depends
on, also called *infrastructure services*, but are not part of OpenStack
itself: a SQL database and an AMPQ message queue server.  OSA supports Galera
and RabbitMQ, respectively.

OSA provides a 'setup-infrastructure.yml' playbook for these services.  Take a
look at the playbook itself:

    # less setup-infrastructure.yml
      ---
      - include: haproxy-install.yml
      - include: memcached-install.yml
      - include: repo-install.yml
      - include: galera-install.yml
      - include: rabbitmq-install.yml
      - include: utility-install.yml
      - include: rsyslog-install.yml

You can tell by looking at the included playbooks that
`setup-infrastructure.yml` installs Haproxy, Memcached, Galera, RabbitMQ,
Rsyslog, and others services.

> Note: You can install services individually by executing the above
> service-specific playbooks separately.

1. To execute the `setup-infrastructure.yml`, run the following, still as
   `root`:

        # openstack-ansible setup-infrastructure.yml

## Deploying OpenStack services.

Once the target hosts and *infrastructure services* are ready, you will deploy the
OpenStack services.

OSA provides a 'setup-openstack.yml' playbook for these services.  Take a
look at the playbook itself:

	# less setup-openstack.yml

	- include: os-keystone-install.yml
	- include: os-glance-install.yml
	- include: os-cinder-install.yml
	- include: os-nova-install.yml
	- include: os-neutron-install.yml
	- include: os-heat-install.yml
	- include: os-horizon-install.yml

You can tell by looking at the included playbooks that
`setup-openstack.yml` installs Keystone, Glance, Cinder, Nova,
Neutron, Heat and Horizon services.

> Note: You can install services individually by executing the above
> service-specific playbooks separately.

1. To execute the `setup-openstack.yml`, run the following, still as
   `root`:

        # openstack-ansible setup-openstack.yml

If the playbook execution is complete and you don't see any item as unreachable or failed 
then you have deployed OpenStack successfully.