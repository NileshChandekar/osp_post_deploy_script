#!/bin/bash
cyan='\033[1;36m'
yellow='\033[1;33m'
NC='\033[0m'
green='\033[0;32m'

sleep 5
overcloud_node_status=$(ironic node-list 2> /dev/null|awk 'NR==4{print $11}')
echo -e "\nChecking the Status of Nodes\n"
echo $overcloud_node_status

while [ "$overcloud_node_status" == "available" ]
do
	sleep 2
	overcloud_node_status=$(ironic node-list 2> /dev/null|awk 'NR==4{print $11}') 
done

until [ $overcloud_node_status == "wait" ]
do
	overcloud_node_status=$(ironic node-list 2> /dev/null|awk 'NR==4{print $11}')
done

if [ "$overcloud_node_status" == "available" ]
then
        echo $overcloud_node_status
        echo -e "\n===================\n"
        echo -e "\nPlease Wait"
fi
if [ "$overcloud_node_status" == "wait" ]
then
        echo -e "\nCurrent State is : $overcloud_node_status"
        echo -e "\n===================\n"
	sleep 7 
        echo -e "\033[5m${cyan}+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo -e "\033[5m${cyan}+                                                   +"
	echo -e "\033[5m${cyan}+                                                   +"
	echo -e "\033[5m${cyan}+   ${green}Please Start the Nodes                        \033[5m${cyan}+"
	echo -e "\033[5m${cyan}+                                                   +"
	echo -e "\033[5m${cyan}+                                                   +"
	echo -e "\033[5m${cyan}+++++++++++++++++++++++++++++++++++++++++++++++++++++${NC}"

fi

while [ "$overcloud_node_status" != "active" ]
do
	overcloud_node_status=$(ironic node-list 2> /dev/null|awk 'NR==4{print $11}') 
done

if [ "$overcloud_node_status" == "active" ]
then
	sleep 15;
	echo -e "\033[5m${cyan}+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo -e "\033[5m${cyan}+                                                   +"
	echo -e "\033[5m${cyan}+                                                   +"
	echo -e "\033[5m${cyan}+   ${green}Please Start the Nodes Once Again              \033[5m${cyan}+"
	echo -e "\033[5m${cyan}+                                                   +"
	echo -e "\033[5m${cyan}+                                                   +"
	echo -e "\033[5m${cyan}+++++++++++++++++++++++++++++++++++++++++++++++++++++${NC}"
fi

