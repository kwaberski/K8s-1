### remove cloud-init
echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
apt-get purge -y cloud-init
sudo rm -rf /etc/cloud/; sudo rm -rf /var/lib/cloud/


### disable swap
# if sudo swapon --show
sudo swapoff -v /swap.img
sudo sed -i -e "s/^\/swap/#\/swap/g" /etc/fstab
sudo rm /swap.img
reboot
