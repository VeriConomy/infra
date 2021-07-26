#!/bin/bash
rsync -e ssh -avz --delete-after --chown=www-data:www-data vrm@10.0.0.15:bootstrap/done/* /home/www/vericonomy/files/vrm/bootstrap
VRMLATEST=$(cat /home/www/vericonomy/files/vrm/bootstrap/LATEST)
rm /home/www/vericonomy/files/vrm/bootstrap/bootstrap.zip || true
ln -s /home/www/vericonomy/files/vrm/bootstrap/$VRMLATEST /home/www/vericonomy/files/vrm/bootstrap/bootstrap.zip
find /home/www/vericonomy/files/vrm/bootstrap/ -mtime +4 -exec rm {} \;
chown -h www-data:www-data /home/www/vericonomy/files/vrm/bootstrap/bootstrap.zip

# Special for ARM
wget -O /home/www/vericonomy/files/vrm/bootstrap-arm/temp-bootstrap.zip http://vericonomy.derasse.ovh/vrm/bootstrap.zip
rm /home/www/vericonomy/files/vrm/bootstrap-arm/bootstrap.zip
mv /home/www/vericonomy/files/vrm/bootstrap-arm/temp-bootstrap.zip /home/www/vericonomy/files/vrm/bootstrap-arm/bootstrap.zip
chown -h www-data:www-data /home/www/vericonomy/files/vrm/bootstrap-arm/bootstrap.zip
