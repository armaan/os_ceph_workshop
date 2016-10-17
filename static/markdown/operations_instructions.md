# Operations.

## Create a glance image.

1. Fetch the image as follows:

        $ cd
        $ wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

2. Add it to Glance:

        $ openstack image create \
            --file cirros-0.3.4-x86_64-disk.img \
            --disk-format qcow2 \
            cirros

3. Verify that it was successful with:

        $ openstack image list

You should see the freshly added image with its status displayed as "active".


## Creating networks in Neutron

Now that Neutron is set up, you can use it to define networks.  In the
`training` user's home directory on `deploy`, you'll find a
`create-neutron-networks.sh` script. It will help you to create an initial set
of networks and routers.

In short, the script creates a virtual `test-net` private network in the
"admin" tenant with a 10.0.6.0/24 mask, and a `test-router` with an interface
in that network.

> Note: It is recommended you open the script and read through it, in order to
> understand how Neutron networks and routers are created from the command
> line.

Simply run it from `deploy` as the `training` user:

1. If you're running as `root` (you can tell by the hash `#` sign on your
   promt), return to the `training` user shell:

        # exit

2. Make sure you're in the `training` user's home directory:

        $ cd

3. Insert the proper credentials into the environment:

        $ source ~/openstackrc

4. Run the script:

        $ ./create-neutron-networks.sh

You can check that it worked by listing all networks:

    $ openstack network list
    ...
    +--------------------------------------+----------+--------------------------------------+
    | ID                                   | Name     | Subnets                              |
    +--------------------------------------+----------+--------------------------------------+
    | b6680bd1-808a-44d9-94db-03891490d0fe | test-net | 517c9938-a6c7-4b47-a6bd-9b099a6c217f |
    +--------------------------------------+----------+--------------------------------------+


## Starting a VM

VMs can be started using any available image in Glance.  You may reference
images either by their name or their ID: both are equally valid.

You'll use the `cirros` image you uploaded earlier into Glance.  You can check
it's `active` with the following command:

    $ openstack image show cirros | grep status

Ideally, when starting a VM you will also assign it a port within a tenant
network. To do so, you need first to pick the network!

1. Run the command below to get a list of Neutron networks available.  Take
   note of the ID of the `test-net` network you created previously.  It is the
   first field on the output of the following command:

        $ openstack network list | grep test-net
        ...
        | 1930d616-6a68-4ff9-886d-5bcc56949a66 | test-net | ...

2. Pick the smallest *flavor* for your VM:

        $ openstack flavor list

3. Run the following in order to launch a guest named "guest0" from the cirros
   image, using the "training" key and the "m1.tiny" flavor. Replace
   `[NETWORK_ID]` with the network ID you obtained above:

        $ openstack server create \
            --image cirros \
            --flavor m1.tiny \
            --nic net-id=[NETWORK_ID] \
            guest0

You can watch the status of the boot as it unfolds with:

    $ watch openstack server list

When the `Status` is "ACTIVE", press CTRL-C to exit.  This means the VM is
running.  You can double-check by printing out the VM's console log:

    $ openstack console log show guest0
    ...
      ____               ____  ____
     / __/ __ ____ ____ / __ \/ __/
    / /__ / // __// __// /_/ /\ \ 
    \___//_//_/  /_/   \____/___/ 
       http://cirros-cloud.net

    login as 'cirros' user. default password: 'cubswin:)'. use 'sudo' for root.


## How to destroy and rebuild service specific containers.

Lets say, we have a horizon container which is misbehaving and we want to
rebuild it.

Destroy a container

   lxc-stop -n alice_horizon_container-7ef1c264
   lxc-destroy -n alice_horizon_container-7ef1c264

Rebuild the container

   openstack-ansible setup-hosts.yml --limit alice \
    --limit alice_horizon_container-7ef1c264

Install the service again   

    openstack-ansible os-horizon-install.yml --limit alice_cinder_api_container-cafcfea0  



## Enable swift api compatible acces to your ceph with radosgw.

Go to _deploy_ machine and execute these lines.

    # source openstackrc

Create a swift user
   
    # openstack user create --domain default --password-prompt swift

Assign admin role to the swift user.
  
    # openstack role add --project service --user swift admin

Create the swift service
  
    # openstack service create --name swift --description \
        "OpenStack  Object Storage" object-store

Create swift endpoints.
    openstack endpoint create --region RegionOne   swift public http://192.168.122.114:8080/swift/v1
    openstack endpoint create --region RegionOne   swift internal http://192.168.122.114:8080/swift/v1
    openstack endpoint create --region RegionOne   swift admin http://192.168.122.114:8080/swift/v1


Add these lines to the ceph.conf file on _daisy_ and restart radosgw.

    rgw keystone url = http://172.29.236.10:35357
    rgw keystone admin user = swift
    rgw keystone admin password = [Password]
    rgw keystone admin tenant = service
    rgw keystone accepted roles = Member, admin, swiftoperator
    rgw keystone token cache size = 500
    rgw keystone revocation interval = 500
    rgw s3 auth use keystone = true
    rgw nss db path = /var/ceph/nss

Restart radosgw service.

    # sudo service radosgw restart id=rgw.daisy

List swift containers:

    # swift list
