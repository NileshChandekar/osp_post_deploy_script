#!/bin/bash
yellow='\033[3;33m'
NC='\033[0m'
echo -e "${yellow}Setting hostname to undercloud-0.example.com${NC}"
echo "============================================"
hostnamectl set-hostname undercloud-0.example.com
hostnamectl set-hostname --transient undercloud-0.example.com

echo -e "${yellow}\nSetting /etc/hosts${NC}"
echo "=================="
echo "127.0.0.1 undercloud-0.example.com undercloud-0" >> /etc/hosts

echo -e "\n${yellow}Check the content of /etc/hosts${NC}"
echo "==============================="
cat /etc/hosts

echo -e "\n${yellow}Creating stack user${NC}"
echo "================="

useradd stack
echo stack | passwd --stdin stack
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack

sleep 5
cp /root/2.sh /home/stack/
cp /root/3.sh /home/stack/
cp /root/4.sh /home/stack/
su stack -c "sh /home/stack/2.sh"
su - stack

