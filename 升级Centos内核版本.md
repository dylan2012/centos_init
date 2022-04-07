一、关于内核版本的定义：
版本性质：主分支ml(mainline)，稳定版(stable)，长期维护版lt(longterm)

版本命名格式为 “A.B.C”：

数字 A 是内核版本号：版本号只有在代码和内核的概念有重大改变的时候才会改变，历史上有两次变化：
第一次是1994年的 1.0 版，第二次是1996年的 2.0 版，第三次是2011年的 3.0 版发布，但这次在内核的概念上并没有发生大的变化
数字 B 是内核主版本号：主版本号根据传统的奇-偶系统版本编号来分配：奇数为开发版，偶数为稳定版
数字 C 是内核次版本号：次版本号是无论在内核增加安全补丁、修复bug、实现新的特性或者驱动时都会改变

二、查看那系统内核版本
# uname -r
3.10.0-514.el7.x86_64
# cat /etc/redhat-release
CentOS Linux release 7.3.1611 (Core)

三、升级内核
1、方法一（可以升级到最新稳定版本，yum安装）：
（1）确认yum源
Centos 6 YUM源：http://www.elrepo.org/elrepo-release-6-6.el6.elrepo.noarch.rpm
Centos 7 YUM源：http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
（2）升级内核需要先导入elrepo的key，然后安装elrepo的yum源：
# rpm -import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
# rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
（3）仓库启用后，可以使用下面的命令列出可用的内核相关包，如下图：
# yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
（4）使用如下命令：(以后这台机器升级内核直接运行这句就可升级为最新稳定版)
# yum -y --enablerepo=elrepo-kernel install kernel-ml.x86_64 kernel-ml-devel.x86_64

四、修改grub中默认的内核版本
内核升级完毕后，目前内核还是默认的版本，如果此时直接执行reboot命令，重启后使用的内核版本还是默认的3.10，不会使用新的4.12.4，首先，我们可以通过命令查看默认启动顺序：

# awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg
vim /etc/default/grub
然后将参数default更改为0即可。
接着运行grub2-mkconfig命令来重新创建内核配置，如下：
# grub2-mkconfig -o /boot/grub2/grub.cfg

五、重启系统并查看系统内核
# reboot
系统启动完毕后，可以通过命令查看系统的内核版本，如下：

# uname -r
