#!/bin/bash
rsync -e ssh -avz --delete-after --chown=www-data:www-data vrc@10.0.0.10:bootstrap/done/* /home/www/vericonomy/files/vrc/2.0/bootstrap
VRCLATEST=$(cat /home/www/vericonomy/files/vrc/bootstrap/LATEST)
rm /home/www/vericonomy/files/vrc/2.0/bootstrap/bootstrap.zip || true
find /home/www/vericonomy/files/vrc/2.0/bootstrap/ -mtime +4 -exec rm {} \;
ln -s /home/www/vericonomy/files/vrc/2.0/bootstrap/$VRCLATEST /home/www/vericonomy/files/vrc/2.0/bootstrap/bootstrap.zip
chown -h www-data:www-data /home/www/vericonomy/files/vrc/2.0/bootstrap/bootstrap.zip

# Special for ARM
wget -O /home/www/vericonomy/files/vrc/2.0/bootstrap-arm/temp-bootstrap.zip http://vericonomy.derasse.ovh/vrc/bootstrap.zip
rm /home/www/vericonomy/files/vrc/2.0/bootstrap-arm/bootstrap.zip
mv /home/www/vericonomy/files/vrc/2.0/bootstrap-arm/temp-bootstrap.zip /home/www/vericonomy/files/vrc/2.0/bootstrap-arm/bootstrap.zip
chown -h www-data:www-data /home/www/vericonomy/files/vrc/2.0/bootstrap-arm/bootstrap.zip
