#!/bin/bash
yellow='\033[1;33m'
NC='\033[0m'
green='\033[1;32m'
echo -e "${yellow}\nInstalling Python-tripleoclient${NC}"
echo "==============================="
sudo yum install -y python-tripleoclient

echo -e "${yellow}\nEnter the interface name of provision network on undercloud node${NC}"
echo "================================================================"
read -p 'Interface Name: ' nic_inter

echo -e "${yellow}\n Creating undercloud.conf${NC}"
echo "========================"
echo -e "[DEFAULT]
# Network interface on the Undercloud that will be handling the PXE
# boots and DHCP for Overcloud instances. (string value)
local_interface = $nic_inter
local_ip = 192.168.24.1/24
#TODO: use release >= 10 when RHBZ#1633193 is resolved
undercloud_ntp_servers=clock.redhat.com
[ctlplane-subnet]
local_subnet = ctlplane-subnet
cidr = 192.168.24.0/24
dhcp_start = 192.168.24.5
dhcp_end = 192.168.24.24
gateway = 192.168.24.1
inspection_iprange = 192.168.24.100,192.168.24.120
masquerade = true
#TODO(skatlapa): add param to override masq" > ~/undercloud.conf

echo -e "${green}\nInstalling undercloud${NC}"
echo "=================="
openstack undercloud install

echo -e "${yellow}\nFollowing is ctlplane on subnet${NC}"
echo "===================================="
source /home/stack/stackrc
openstack network list

