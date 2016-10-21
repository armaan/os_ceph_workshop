# Deploy Ceph

## What is CEPH

Ceph is an open source project that provides unified software defined solutions for 
Block, File, and Object storage. Ceph provides a distributed storage system that is
massively scalable with no single point of failure.

## What is ceph-ansible

ceph-ansible is an opensource project for deploying
ceph with ansible playbooks. You can know more about it here
https://github.com/ceph/ceph-ansible.git

We are going to use `ceph-ansible` for deploying OSDs, Monitors and
RGW in our Ceph cluster. 

Ceph Monitors(MON): Ceph monitors track the health of the entire cluster by
keeping a map of the cluster state. It maintains a seperate map of information for
each component, which includes mon pap, osd map, pg map and crush map.

Ceph Object Storage Device(OSD): Data gets stored in the OSD in the form of objects.
Usually one OSD daemon is tied to one physical disk in your cluster.

RADOS Gateway interface: RGW provides object storage service. RGW provides RESTful APIs
with interfaces that are compatible with Amazon S3 and OpenStack Swift.


## Lab Overview

The lab environment is accessed via the terminal screen embedded below.  To
find it, simply scroll down.

The lab environment consists of five virtual machines, accessible via the
following local IP addresses.

* _deploy_: **`192.168.122.100`**
* _alice_: **`192.168.122.111`**
* _bob_: **`192.168.122.112`**
* _charlie_: **`192.168.122.113`**
* _daisy_: **`192.168.122.114`**

The _deploy_ node  has a publicly available IP address.
Your terminal automatically connects to _deploy_.

Since `openstack-ansible` and `ceph-ansible` uses different versions
of ansible; we will be deploying `ceph-asbile` from the _daisy_ machine and
`openstack-ansible` from the _deploy_ machine.


When you connect to _deploy_, you automatically enter a `screen` session.
`screen` is a terminal multiplexer that, among other things, allows you
reconnect to a previous session.  This means that if you close the browser page
and return to the exercise later on, your session, including scrollback and
command history, will be exactly as you left it.

## SSH Between Nodes

You can use SSH from _deploy_ to hop to the other nodes.  To connect to
_daisy_, follow these instructions using the terminal below:

1. From the _deploy_ node (it's where you start out), SSH into _daisy_ by
   entering:

        $ sudo -i
        # ssh daisy

2. From the _daisy_ node, SSH into _bob_ by entering:

        # ssh 192.168.122.112
        # exit  

3. To confirm the authenticity of the host, enter "yes" at the prompt.

4. Type the following to return to `daisy`:

        # exit

5. From the _daisy_ node, SSH into _charlie_ by entering:

        # ssh 192.168.122.113
        # exit


> Note: Whenever specific instructions are given as the ones above, do your
> best to execute them as stated. You will be graded on the results.

## Configuration

You will need to configure the following files to use ceph-ansible for deploying Ceph

1. ceph-ansible/group_vars/all
2. ceph-ansible/group_vars/osds
3. ceph-ansible/hosts


Let's have a look at the hosts file.
	
    # cd /home/training/ceph-ansible
    # cat hosts

You should see something like this:

    [mons]
    192.168.122.11[2:4]


    [osds]
    192.168.122.114

    [rgws]
    192.168.122.11[2:4]

As you can see we are deploying 3 ceph monitors(mons) on _bob_, _charlie_ and _daisy_.
We are using only one OSD node i.e. _daisy_ and 3 radosgw instances.

## Deploy Ceph

From the _daisy_ node, execute these instructions.

    # cd /home/training/ceph-ansible
    # ansible-playbook -i hosts site.yml

Once the ansible run is complete you should see an output like this:

    PLAY RECAP *********************************************************************
    192.168.122.112            : ok=93   changed=6    unreachable=0    failed=0
    192.168.122.113            : ok=89   changed=1    unreachable=0    failed=0
    192.168.122.114            : ok=154  changed=7    unreachable=0    failed=0



Let's check the health of Ceph cluster.

    # ceph -s

    cluster 1e2ab4e5-2d1e-4587-b1ac-0ec336414b8a
    health HEALTH_OK
    monmap e1: 3 mons at {bob=192.168.122.112:6789/0,charlie=192.168.122.113:6789/0,daisy=192.168.122.114:6789/0}
            election epoch 138, quorum 0,1,2 bob,charlie,daisy
    osdmap e21: 1 osds: 1 up, 1 in
            flags sortbitwise
    pgmap v3644: 112 pgs, 7 pools, 12979 kB data, 179 objects
            55856 kB used, 10174 MB / 10228 MB avail
                 112 active+clean
  	client io 12627 B/s rd, 0 B/s wr, 12 op/s rd, 8 op/s wr

Unless, you see the cluster in ERROR state. You are good to proceed ahead.

## Create a ceph client for Openstack services

From _daisy_ machine:

    # sudo ceph auth get-or-create-key client.cinder
    # sudo ceph auth caps client.cinder  mon 'allow *' osd 'allow *'


Let's proceed to the next lab i.e. Deploying OpenStack.


