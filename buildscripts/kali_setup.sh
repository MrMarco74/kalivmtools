mkdir /home/kali/setup
cd /home/kali/setup/
cat <<EOF >/etc/default/keyboard 
# KEYBOARD CONFIGURATION FILE
# Consult the keyboard(5) manual page.
XKBMODEL="pc105"
XKBLAYOUT="de"
XKBVARIANT=""
XKBOPTIONS="lv3:ralt_switch"
BACKSPACE="guess"
EOF

service keyboard-setup restart
apt-get update && sudo apt-get dist-upgrade -y
apt install ssh -y
service ssh start
apt install links terminator tmux slurm nload htop iftop cntlm -y

#https://www.kali.org/docs/general-use/xfce-with-rdp/
apt-get install xrdp -y
cat <<EOF | sudo tee /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
service xrdp start
service xrdp-sesman start
update-rc.d xrdp enable

curl --request GET --url 'https://portswigger-cdn.net/burp/releases/download?product=pro&version=2023.10.2&type=Linux' --output 'burp_latest.sh'
chmod +x burp_latest.sh
./burp_latest.sh -q

apt install gvm -y
gvm-setup
sudo runuser -u _gvm -- greenbone-feed-sync --type SCAP
sudo -E -u _gvm -g _gvm gvmd --user=admin --new-password=kali
#gvm-start
cd ..
rm -rf setup
apt-get autoremove -y
apt-get clean -y

curl --request GET --url 'https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.6.0-debian10_amd64.deb' --output 'Nessus-10.6.0-debian10_amd64.deb'
dpkg -i Nessus-10.6.0-debian10_amd64.deb
service nessusd start
#/opt/nessus/sbin/nessuscli update --all
#/opt/nessus/sbin/nessusd -R

apt update
apt dist-upgrade -y --fix-missing
apt autoremove -y
apt autoclean -y
