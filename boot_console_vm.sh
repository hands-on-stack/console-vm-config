DNS_SERVER_1st=8.8.8.8
DNS_SERVER_2nd=8.8.4.4

neutron net-create handson-net
neutron subnet-create --ip-version 4 --gateway 10.20.30.254 \
--name handson-subnet \
--dns-nameserver $DNS_SERVER_1st \
--dns-nameserver $DNS_SERVER_2nd \
handson-net 10.20.30.0/24
neutron router-interface-add Ext-Router handson-subnet

nova keypair-add key-for-console-vm | tee key-for-console-vm.pem
chmod 600 key-for-console-vm.pem

neutron security-group-create sg-for-console-vm
neutron security-group-rule-create --ethertype IPv4 \
--protocol tcp --port-range-min 22 --port-range-max 22 \
--remote-ip-prefix 0.0.0.0/0 sg-for-console-vm
neutron security-group-rule-create --ethertype IPv4 \
--protocol tcp --port-range-min 3389 --port-range-max 3389 \
--remote-ip-prefix 0.0.0.0/0 sg-for-console-vm

function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
MY_WORK_NET=`neutron net-show handson-net | get_uuid`

IMAGE_ID=`glance image-list |grep -i fedora |grep -v deprecated |grep " 20 " | awk '{print $2}'`
AZ_NAME=az1

nova boot --flavor standard.small \
--image "${IMAGE_ID:?}" \
--key-name key-for-console-vm \
--security-groups sg-for-console-vm \
--user-data userdata_f20.txt \
--availability-zone ${AZ_NAME:?} \
--nic net-id=${MY_WORK_NET:?} console-vm

