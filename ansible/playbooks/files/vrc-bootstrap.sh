#!/bin/bash
export HOMEDIR=/home/vrc
cd $HOMEDIR
mkdir -p $HOMEDIR/bootstrap/doing
mkdir -p $HOMEDIR/bootstrap/done

# Cleanup
rm -rf $HOMEDIR/bootstrap/doing/*
find $HOMEDIR/bootstrap/done/ -mtime +3 -exec rm {} \;

# stop wallet
$HOMEDIR/wallet/src/vericoin-cli stop || true
sleep 10

# Create bootstrap
mkdir -p $HOMEDIR/bootstrap/doing/bootstrap/
touch $HOMEDIR/bootstrap/doing/bootstrap/vericonomy.conf
echo "[verium]" >> $HOMEDIR/bootstrap/doing/bootstrap/vericonomy.conf
curl -s https://chainz.cryptoid.info/vrm/api.dws?q=nodes | jq -r '.[2].nodes | "addnode=" + .[]' >> $HOMEDIR/bootstrap/doing/bootstrap/vericonomy.conf
echo "" >> $HOMEDIR/bootstrap/doing/bootstrap/vericonomy.conf
echo "[vericoin]" >> $HOMEDIR/bootstrap/doing/bootstrap/vericonomy.conf
curl -s https://chainz.cryptoid.info/vrc/api.dws?q=nodes | jq -r '.[2].nodes | "addnode=" + .[]' >> $HOMEDIR/bootstrap/doing/bootstrap/vericonomy.conf
cp -r .vericonomy/vericoin/blocks .vericonomy/vericoin/chainstate .vericonomy/vericoin/indexes $HOMEDIR/bootstrap/doing/bootstrap/

# Relaunch wallet
$HOMEDIR/wallet/src/vericoind --daemon

# Prepare zip
cd $HOMEDIR/bootstrap/doing/
zip -r "$HOMEDIR/bootstrap/done/bootstrap-$(date +"%Y-%m-%d").zip" bootstrap
echo "bootstrap-$(date +"%Y-%m-%d").zip" > $HOMEDIR/bootstrap/done/LATEST

