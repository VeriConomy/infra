#!/bin/bash
rsync -e ssh -avz --delete-after --chown=www-data:www-data vrm@10.0.0.15:bootstrap/done/* /home/www/vericonomy/files/vrm/bootstrap
VRMLATEST=$(cat /home/www/vericonomy/files/vrm/bootstrap/LATEST)
rm /home/www/vericonomy/files/vrm/bootstrap/bootstrap.zip || true
ln -s /home/www/vericonomy/files/vrm/bootstrap/$VRMLATEST /home/www/vericonomy/files/vrm/bootstrap/bootstrap.zip
find /home/www/vericonomy/files/vrm/bootstrap/ -mtime +4 -exec rm {} \;
chown -h www-data:www-data /home/www/vericonomy/files/vrm/bootstrap/bootstrap.zip

rsync -e ssh -avz --delete-after --chown=www-data:www-data vrc@10.0.0.10:bootstrap/done/* /home/www/vericonomy/files/vrc/bootstrap
VRCLATEST=$(cat /home/www/vericonomy/files/vrc/bootstrap/LATEST)
rm /home/www/vericonomy/files/vrc/bootstrap/bootstrap.zip || true
find /home/www/vericonomy/files/vrc/bootstrap/ -mtime +4 -exec rm {} \;
ln -s /home/www/vericonomy/files/vrc/bootstrap/$VRCLATEST /home/www/vericonomy/files/vrc/bootstrap/bootstrap.zip
chown -h www-data:www-data /home/www/vericonomy/files/vrc/bootstrap/bootstrap.zip
