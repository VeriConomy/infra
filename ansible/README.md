# Ansible

## How to launch

```
ansible-playbook playbooks/...
```

You can also apply all playbooks by launching
```
ansible-playbook playbooks/all.yml
```

## Playbook list

* **base.yml**: Do a basic configuration of the system such as install package

## Initial preparation of the infrastructure

On Proxmox server
```
lxc-exec-all apt-get update
lxc-exec-all apt-get install --no-install-recommends -y sudo
lxc-exec-all adduser --system --shell /bin/bash --group --disabled-password --home /home/ansible ansible
lxc-exec-all usermod -aG sudo ansible
lxc-exec-all mkdir -p  /home/ansible/.ssh
lxc-exec-all chmod 700 /home/ansible/.ssh
lxc-exec-all chown ansible:ansible /home/ansible/.ssh
lxc-exec-all "echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible"

apt-get update
apt-get install --no-install-recommends -y sudo
adduser --system --shell /bin/bash --group --disabled-password --home /home/ansible ansible
usermod -aG sudo ansible
mkdir -p  /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chown ansible:ansible /home/ansible/.ssh
echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible
```

On Deploy Server
```
sudo -H -u ansbile
ssh-keygen -t ed25519 -a 100
cat /home/ansible/.ssh/id_ed25519.pub
```
Keep the public key !

On Proxmox server
```
lxc-exec-all "echo 'REPLACE BY THE PUBLIC KEY' > /home/ansible/.ssh/authorized_keys"
lxc-exec-all chown -R ansible:ansible /home/ansible/.ssh


echo 'REPLACE BY THE PUBLIC KEY' > /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/.ssh
```

On Deploy Server
```
apt update
apt install python3-pip git
pip3 install ansible
```

You also might need to add the public key to the Github Deployment App