#! /bin/bash
# обновление ядра CentOS 7
cd /tmp
yum -y update
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum install http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install kernel-ml
grub2-mkconfig -o /boot/grub2/grub.cfg
echo "exclude=kernel* grub*" >> /etc/yum.conf
reboot
