ovs-vsctl add-br br-int-api
ip link add name vxlan1 type vxlan id 43 dev l3 group 239.0.0.2
ovs-vsctl add-port br-int-api vxlan1
ip link set dev vxlan1 up
ovs-vsctl add-br br-mgmt
ip link add name vxlan2 type vxlan id 44 dev l3 group 239.0.0.3
ovs-vsctl add-port br-mgmt vxlan2
ip link set dev vxlan2 up

cat << EOF > br-int-api.xml
<network>
  <name>br-int-api</name>
  <forward mode='bridge'/>
  <bridge name='br-int-api'/>
  <virtualport type='openvswitch'/>
</network>
EOF

cat << EOF > br-mgmt.xml
<network>
  <name>br-mgmt</name>
  <forward mode='bridge'/>
  <bridge name='br-mgmt'/>
  <virtualport type='openvswitch'/>
</network>
EOF

virsh net-define br-int-api.xml
virsh net-define br-mgmt.xml
virsh net-start br-int-api
virsh net-autostart br-int-api
virsh net-start br-mgmt
virsh net-autostart br-mgmt
ovs-vsctl add-port br-int-api int-api -- set interface int-api type=internal
ip addr add 10.0.0.1/24 dev int-api
ip link set dev int-api up
ovs-vsctl add-port br-mgmt mgmt -- set interface mgmt type=internal
ip addr add 10.1.0.1/24 dev mgmt
ip link set dev mgmt up

for i in `virsh list --all |grep baremetalbrbm_ |awk '{print $2}' | tr -d ' '`
do
  virsh attach-interface --domain $i --type network --source br-int-api --model virtio --config
  virsh attach-interface --domain $i --type network --source br-mgmt --model virtio --config
done
