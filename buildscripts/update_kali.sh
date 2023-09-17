service nessusd stop
apt update
apt dist-upgrade -y --fix-missing
apt autoremove -y
apt autoclean -y
openvas-feed-update
/opt/nessus/sbin/nessuscli update --all
/opt/nessus/sbin/nessusd -R
service nessusd start
apt clean all -y
