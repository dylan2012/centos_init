rpm -ivh https://repo.zabbix.com/zabbix/5.4/rhel/7/x86_64/zabbix-agent-5.4.8-1.el7.x86_64.rpm
systemctl enable zabbix-agent.service
sed -i 's/^Server=.*/Server=45.136.119.166/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^ServerActive=.*/ServerActive=45.136.119.166/g' /etc/zabbix/zabbix_agentd.conf
sed -i "s/^Hostname.*/Hostname = `hostname`/g" /etc/zabbix/zabbix_agentd.conf
sed -i '/^# HostMetadataItem=/a HostMetadataItem=system.uname' /etc/zabbix/zabbix_agentd.conf
systemctl start zabbix-agent

wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest-cli
./speedtest-cli
yum -y install hdparm
hdparm -t --direct /dev/sda
dd bs=128k count=10k if=/dev/zero of=test
