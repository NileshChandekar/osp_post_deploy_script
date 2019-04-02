#!/bin/bash
yellow='\033[1;33m'
NC='\033[0m'
green='\033[0;32m'
cyan='\033[1;36m'

source /home/stack/stackrc

echo -e "${yellow}\nObtaining Images for overcloud nodes${NC}"
echo "===================================="
sudo yum install rhosp-director-images rhosp-director-images-ipa -y
mkdir ~/images
mkdir ~/templates
cd  ~/images


echo -e "${yellow}\nExtracting Images"
echo "==================="
for i in /usr/share/rhosp-director-images/overcloud-full-latest-13.0.tar /usr/share/rhosp-director-images/ironic-python-agent-latest-13.0.tar; do tar -xvf $i; done

echo -e "${yellow}\nUploading Images for Overcloud"
echo "==============================="
openstack overcloud image upload --image-path /home/stack/images/

echo  -e "${yellow}\nFollowing images uploaded${NC}"
echo "========================="
openstack image list

read -p 'Do you want ceph nodes[y/n]: ' ceph_input
ceph_input='n'
if [ $ceph_input == y ]
then
        read -p '${green}\nPlease enter number of ceph nodes ' ceph_input
        echo -e "${yellow}\nSetting up the local Container registry${NC}"
        echo "======================================="
        sudo openstack overcloud container image prepare \
          --namespace=registry.access.redhat.com/rhosp13 \
          --push-destination=192.168.24.1:8787 \
          --prefix=openstack- \
          --tag-from-label {version}-{release} \
          --set ceph_namespace=192.168.24.1:8787 \
          --set ceph_image=rceph \
          --set ceph_tag=3-16 \
          --output-env-file=/home/stack/templates/overcloud_images.yaml \
          --output-images-file /home/stack/local_registry_images.yaml
else
        echo -e "${yellow}\nSetting up the local Container registry${NC}"
        echo "======================================="
        sudo openstack overcloud container image prepare \
          --namespace=registry.access.redhat.com/rhosp13 \
          --push-destination=192.168.24.1:8787 \
          --prefix=openstack- \
          --tag-from-label {version}-{release} \
          --output-env-file=/home/stack/templates/overcloud_images.yaml \
          --output-images-file /home/stack/local_registry_images.yaml
fi

sleep 10;

echo  -e "${yellow}\nuploading container Images to the Undercloud${NC}"
echo "===================================================="
openstack overcloud container image upload --config-file  /home/stack/local_registry_images.yaml --verbose

echo -e "${yellow}\nEnabling fake_pxe"
echo "===================="
sudo sed -i '/enabled_drivers/s/$/,fake_pxe/' /etc/ironic/ironic.conf
sudo systemctl restart openstack-ironic-api openstack-ironic-conductor

file="/home/stack/instackenv.json"
if [ -f "$file" ]
then
	rm -rf /home/stack/instackenv.json
fi

read -p 'Please enter number of compute nodes: ' compute_input
read -p 'Please enter number of controller nodes: ' controller_input

for (( con=1;con<=$controller_input;con++ ));

do
        echo -e "\n\nEnter Mac for controller$con: "
        read ctrl$con_mac
        if [ $con == 1 ]
        then
                echo -e "{\n\"nodes\":[\n{\n\"mac\":[\"$ctrl$con_mac\"\n],\n\"name\":\"Controller$con\",\n\"pm_type\":\"fake_pxe\"\n}," >> /home/stack/instackenv.json
        elif [ $con -gt 1 ]
        then
                echo -e "\n{\n\"mac\":[\"$ctrl$con_mac\"\n],\n\"name\":\"Controller$con\",\n\"pm_type\":\"fake_pxe\"\n}," >> /home/stack/instackenv.json
        fi
done

for (( com=1;com<=$compute_input;com++ ));
do
        echo -e "\n\nEnter Mac for Compute$com: "
        read cmpt$con_mac
        if [ $compute_input -gt $com ]
        then
                echo -e "\n{\n\"mac\":[\"$cmpt$con_mac\"\n],\n\"name\":\"Compute$com\",\n\"pm_type\":\"fake_pxe\"\n}," >> /home/stack/instackenv.json
        fi
        if [ $com == $compute_input ]
        then
                echo -e "\n{\n\"mac\":[\"$cmpt$con_mac\"\n],\n\"name\":\"Compute$com\",\n\"pm_type\":\"fake_pxe\"\n}\n]\n}" >> /home/stack/instackenv.json
        fi
done


echo -e "${yellow}\nGenerated instackenv file as below:${NC}"
echo "==================================="

cat /home/stack/instackenv.json
sleep 5

echo -e "${yellow}\nEnrolling Nodes${NC}"
echo "==============="
openstack overcloud node import /home/stack/instackenv.json
sleep 2


echo -e "${yellow}\nNode List${NC}"
echo "==============="
ironic node-list

echo -e "${yellow}\nIntrospecting the nodes${NC}"
echo "======================="

echo -e "\033[5m${cyan}+++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo -e "\033[5m${cyan}+                                                   +"
echo -e "\033[5m${cyan}+                                                   +"
echo -e "\033[5m${cyan}+   ${green}Start your nodes in 5 seconds                  \033[5m${cyan}+"   
echo -e "\033[5m${cyan}+                                                   +"
echo -e "\033[5m${cyan}+                                                   +"
echo -e "\033[5m${cyan}+++++++++++++++++++++++++++++++++++++++++++++++++++++${NC}"

openstack overcloud node introspect --all-manageable --provide


echo -e "\033[5m${cyan}+++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo -e "\033[5m${cyan}+                                                   +"
echo -e "\033[5m${cyan}+                                                   +"
echo -e "\033[5m${cyan}+   ${green}Please Turn OFF the Nodes                     \033[5m${cyan}+"   
echo -e "\033[5m${cyan}+                                                   +"
echo -e "\033[5m${cyan}+                                                   +"
echo -e "\033[5m${cyan}+++++++++++++++++++++++++++++++++++++++++++++++++++++${NC}"

echo -e "${yellow}\nTagging Nodes into Profiles${NC}"
echo "============================"

for i in $(openstack baremetal node list |grep -i compute |awk '{print $2}') ; do 
	openstack baremetal node set --property capabilities='profile:compute,boot_option:local'  $i ;
done

for i in $(openstack baremetal node list |grep -i control |awk '{print $2}') ; do 
	openstack baremetal node set --property capabilities='profile:control,boot_option:local'  $i ;
done

echo -e "${yellow}\nChecking Nodes Profiles${NC}"
echo "============================"
openstack overcloud profiles list

sh /home/stack/4.sh &

