# Ansible

## How to launch

```
ansible-playbook playbooks/...
```

You can also apply all playbooks by launching
```
ansible-playbook playbooks/all.yml
```

## Initial preparation of the infrastructure
###

```
lxc-exec-all apt-get update
lxc-exec-all apt-get install --no-install-recommends -y sudo
lxc-exec-all adduser --system --shell /bin/bash --group --disabled-password --home /home/ansible ansible
lxc-exec-all usermod -aG sudo ansible
lxc-exec-all mkdir -p  /home/ansible/.ssh
lxc-exec-all chmod 700 /home/ansible/.ssh
lxc-exec-all chown ansible:ansible /home/ansible/.ssh

---> Connect to deploy server
sudo -H -u ansbile
ssh-keygen -t ed25519 -a 100
cat /home/ansible/.ssh/id_ed25519.pub
----

lxc-exec-all "echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsaOsAj2x/NoydspopPPGsMKBu+F/hfHaNf2/AWaM4E ansible@deploy' > /home/ansible/.ssh/authorized_keys"
lxc-exec-all chown -R ansible:ansible /home/ansible/.sshlxc-exec-all "echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsaOsAj2x/NoydspopPPGsMKBu+F/hfHaNf2/AWaM4E ansible@deploy' > /home/ansible/.ssh/authorized_keys"
lxc-exec-all chown -R ansible:ansible /home/ansible/.ssh

---> Connect to deploy server
apt update
apt install python3-pip git
pip3 install ansible
----


Also add ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsaOsAj2x/NoydspopPPGsMKBu+F/hfHaNf2/AWaM4E ansible@deploy
```