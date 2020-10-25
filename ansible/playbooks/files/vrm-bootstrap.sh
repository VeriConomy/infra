#!/bin/bash
export HOMEDIR=/home/vrm
cd $HOMEDIR
mkdir -p $HOMEDIR/bootstrap/doing
mkdir -p $HOMEDIR/bootstrap/done

# Cleanup
rm -rf $HOMEDIR/bootstrap/doing/*
find $HOMEDIR/bootstrap/done/ -mtime +5 -exec rm {} \;

# stop wallet
$HOMEDIR/wallet/src/verium-cli stop || true
sleep 10

# Create bootstrap
mkdir -p $HOMEDIR/bootstrap/doing/bootstrap/
touch $HOMEDIR/bootstrap/doing/bootstrap/verium.conf
curl -s https://chainz.cryptoid.info/vrm/api.dws?q=nodes | jq -r '.[2].nodes | "addnode=" + .[]' >> $HOMEDIR/bootstrap/doing/bootstrap/verium.conf
cp -r .verium/blocks .verium/chainstate $HOMEDIR/bootstrap/doing/bootstrap/

# Relaunch wallet
$HOMEDIR/wallet/src/veriumd --daemon

# Prepare zip
cd $HOMEDIR/bootstrap/doing/
zip -r "$HOMEDIR/bootstrap/done/bootstrap-$(date +"%Y-%m-%d").zip" bootstrap
echo "bootstrap-$(date +"%Y-%m-%d").zip" > $HOMEDIR/bootstrap/done/LATEST
