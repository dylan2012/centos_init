#!/bin/bash
[ $(id -u) != "0" ] && { echo "Please use the root user to run this script." && exit 1; }

COLOR="echo -e \\033[01;31m"
END='\033[0m'

checkOSinfo() {
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_NAME=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+) (.*)"$@\2@p' /etc/os-release`
    OS_RELEASE=`sed -rn '/^VERSION_ID=/s@.*="?([0-9.]+)"?@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
	
	echo "Your Server OS it's ${OS_ID} ${OS_RELEASE}"
}

setssh() {
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" ];then
        sed -ri.bak -e 's/^#(UseDNS).*/\1 no/' -e 's/^(GSSAPIAuthentication).*/\1 no/' /etc/ssh/sshd_config
    else
        sed -ri.bak -e 's/^#(UseDNS).*/\1 no/' -e 's/^#(GSSAPIAuthentication).*/\1 no/' /etc/ssh/sshd_config
    fi
    systemctl restart sshd
    ${COLOR}"${OS_ID} ${OS_RELEASE} SSH已优化完成!"${END}
	
	sed -ri 's/^(PasswordAuthentication).*/\1 yes/' /etc/ssh/sshd_config
	sed -ri 's/.*(PermitRootLogin).*/\1 yes/' /etc/ssh/sshd_config
	service sshd restart
}

addYUM() {
	dnf -y install epel-release
}

updateYUM() {
	dnf clean all && yum makecache
	rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
	#dnf groupinstall "Development Tools"  #编译环境
	dnf -y install lshw vim tree bash-completion git xorg-x11-xauth xterm gettext tmux vnstat man screen crontabs wget curl iproute tar gdisk iotop iftop htop bind-utils telnet mtr  lrzsz
	. /etc/bash_completion
	dnf update -y
}

changZHCN() {
    localectl set-locale LANG=zh_CN.utf8
	localectl set-keymap cn
	localectl set-x11-keymap cn
	timedatectl set-timezone Asia/Shanghai
}

addBINscript() {
	[ -x /bin/systeminfo ] && break
	curl -Lks 'https://raw.githubusercontent.com/dylan2012/centos_init/master/securityremove' > /bin/securityremove
	curl -Lks 'https://raw.githubusercontent.com/dylan2012/centos_init/master/systeminfo' > /bin/systeminfo
	curl -Lks 'https://raw.githubusercontent.com/dylan2012/centos_init/master/vimrc' > /root/.vimrc
	chmod +x /bin/{securityremove,systeminfo}
	test -f /etc/bash.bashrc && sed -i "/securityremove/d" /etc/bash.bashrc && echo 'alias rm="/bin/securityremove"' >> /etc/bash.bashrc && . /etc/bash.bashrc
	test -f /etc/bashrc && sed -i "/securityremove/d" /etc/bashrc && echo 'alias rm="/bin/securityremove"' >> /etc/bashrc && . /etc/bashrc
	test -f /root/.bashrc && sed -i "/alias rm/d" /root/.bashrc && echo 'alias rm="/bin/securityremove"' >> /root/.bashrc && . /root/.bashrc
	if ! grep "alias vi='vim'" /root/.bashrc &>/dev/null; then
		cat >> /root/.bashrc <<-EOF
			alias vi='vim'
			alias last='last -i'
			alias grep='grep --color=auto'
			export VISUAL=vim
			export EDITOR=vim
		EOF
		#sed -i 's/.*set hlsearch.*/"&/' /etc/vimrc
	fi
}

setPS1() {
	curl -Lks 'https://raw.githubusercontent.com/dylan2012/centos_init/master/PS1' >> /etc/profile

	for i in `find /home/ -name '.bashrc'` /etc/skel/.bashrc ~/.bashrc ;do
		cat >> $i <<-EOF
			xterm_set_tabs() {
				TERM=linux
				export \$TERM
				setterm -regtabs 4
				TERM=xterm
				export \$TERM
			}

			linux_set_tabs() {
				TERM=linux;
				export \$TERM
				setterm -regtabs 8
				LESS="-x4"
				export LESS
			}

			#[ \$(echo \$TERM) == "xterm" ] && xterm_set_tabs
			linux_set_tabs

			listipv4() {
				if [ "\$1" != "lo" ]; then
					which ifconfig >/dev/null 2>&1 && ifconfig | sed -rn '/^[^ \\t]/{N;s/(^[^ ]*).*addr:([^ ]*).*/\\1=\\2/p}' | \\
						awk -F= '\$2!~/^192\\.168|^172\\.(1[6-9]|2[0-9]|3[0-1])|^10\\.|^127|^0|^\$/{print}' \\
						|| ip addr | awk '\$1=="inet" && \$NF!="lo"{print \$NF"="\$2}'
				else
					which ifconfig >/dev/null 2>&1 && ifconfig | sed -rn '/^[^ \\t]/{N;s/(^[^ ]*).*addr:([^ ]*).*/\\1=\\2/p}' \\
					|| ip addr | awk '\$1=="inet" && \$NF!="lo"{print \$NF"="\$2}'
				fi
			}

			tmux_init() {
				tmux new-session -s "LookBack" -d -n "local"    # 开启一个会话
				tmux new-window -n "other"          # 开启一个窗口
				tmux split-window -h                # 开启一个竖屏
				tmux split-window -v "htop"          # 开启一个横屏,并执行top命令
				tmux -2 attach-session -d           # tmux -2强制启用256color，连接已开启的tmux
			}
			# 判断是否已有开启的tmux会话，没有则开启
			#if which tmux 2>&1 >/dev/null; then test -z "\$TMUX" && { tmux attach || tmux_init; };fi
		EOF
	done
}

setSELinux() {
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" ];then
        if [ `getenforce` == "Enforcing" ];then
            sed -ri.bak 's/^(SELINUX=).*/\1disabled/' /etc/selinux/config
            ${COLOR}"${OS_ID} ${OS_RELEASE} SELinux已禁用,请重新启动系统后才能生效!"${END}
        else
            ${COLOR}"${OS_ID} ${OS_RELEASE} SELinux已被禁用,不用设置!"${END}
        fi
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} SELinux默认没有安装,不用设置!"${END}
    fi
}

dockerINSTALL() {
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
	dnf install docker-ce --allowerasing -y
	systemctl enable --now docker
	sudo curl -L "https://github.com/docker/compose/releases/download/v2.2.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x  /usr/local/bin/docker-compose
}


setSYSCTL() {
	cp /etc/sysctl.conf{,_$(date "+%Y%m%d_%H%M%S")_backup}
	cat > /etc/sysctl.conf <<-EOF
		fs.file-max=65535
		net.ipv4.tcp_max_tw_buckets = 60000
		net.ipv4.tcp_sack = 1
		net.ipv4.tcp_window_scaling = 1
		net.ipv4.tcp_rmem = 4096 87380 4194304
		net.ipv4.tcp_wmem = 4096 16384 4194304
		net.ipv4.tcp_max_syn_backlog = 65536
		net.core.netdev_max_backlog = 32768
		net.core.somaxconn = 32768
		net.core.wmem_default = 8388608
		net.core.rmem_default = 8388608
		net.core.rmem_max = 16777216
		net.core.wmem_max = 16777216
		net.ipv4.tcp_timestamps = 0
		net.ipv4.tcp_synack_retries = 2
		net.ipv4.tcp_syn_retries = 2
		#net.ipv4.tcp_tw_recycle = 1
		#net.ipv4.tcp_tw_len = 1
		net.ipv4.tcp_tw_reuse = 1
		net.ipv4.tcp_mem = 94500000 915000000 927000000
		net.ipv4.tcp_max_orphans = 3276800
		net.ipv4.ip_local_port_range = 1024 65000

		net.nf_conntrack_max = 6553500
		net.netfilter.nf_conntrack_max = 6553500
		net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
		net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
		net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
		net.netfilter.nf_conntrack_tcp_timeout_established = 3600

		net.ipv4.conf.all.rp_filter = 2
		net.ipv4.ip_forward = 1
	EOF
}
main() {
	checkOSinfo
	setssh
	addYUM
	updateYUM
	changZHCN
	addBINscript
	setPS1
	setSELinux
	setSYSCTL && sysctl -p
	dockerINSTALL
}

main ${@} && [ -x /bin/systeminfo ] && clear; systeminfo all
rm -rf $0
