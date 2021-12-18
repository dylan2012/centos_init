#!/bin/bash
[ $(id -u) != "0" ] && { echo "Please use the root user to run this script." && exit 1; }

checkOSinfo() {
	if [ -f /etc/centos-release ]; then
		release=`awk '{print int(($3~/^[0-9]/?$3:$4))}' /etc/centos-release`
		OS=CentOS
	elif [ -f /etc/redhad-release ]; then
		release=`awk '{print int(($3~/^[0-9]/?$3:$4))}' /etc/redhat-release`
		OS=RedHat
	elif [ -f /etc/os-release ]; then
		. /etc/os-release
		[ "`awk '{print $1}' <<<$NAME`" = "Ubuntu" ] && { release=`awk '{print int($1)}' <<<$VERSION_ID` && OS=`awk '{print $1}' <<<$NAME`; }
		[ "`awk '{print $1}' <<<$NAME`" = "Debian" ] && { release=$VERSION_ID && OS=`awk '{print $1}' <<<$NAME`; }
	fi

	[ `getconf WORD_BIT` == 32 ] && [ `getconf LONG_BIT` == 32 ] && BIT=32 || BIT=64
	[ "$OS" != "CentOS" -a "$OS" != "RedHat" ] && { echo "Your Server OS it's CentOS or RedHat" && exit 1; }
}

setssh() {
	sed -ri 's/^(PasswordAuthentication).*/\1 yes/' /etc/ssh/sshd_config
	sed -ri 's/.*(PermitRootLogin).*/\1 yes/' /etc/ssh/sshd_config
	service sshd restart

	[ ! -d ~/.ssh ] && mkdir ~/.ssh && chmod og=--- ~/.ssh
	#curl -Lks onekey.sh/ssh|bash

}

addYUM() {
	yum -y install epel-release
}

updateYUM() {
	yum clean all && yum makecache
	#sed -i '/[main]/a exclude=kernel*' /etc/yum.conf
	yum -y install lshw vim tree bash-completion git xorg-x11-xauth xterm \
		gettext axel tmux vnstat man vixie-cron screen vixie-cron crontabs \
		wget curl iproute tar gdisk iotop iftop htop bind-utils telnet mtr ntpdate
	. /etc/bash_completion
	[ "$release" = "6" ] && yum -y groupinstall "Development tools" "Server Platform Development"
	[ "$release" = "7" ] && yum -y groups install "Development Tools" "Server Platform Development"
	yum update -y
}

changZHCN() {
	if [ "$release" = "6" ]; then
		yum groupinstall "Chinese Support" -y
		cat > /etc/sysconfig/i18n <<-EOF
			#LANG=C
			#SYSFONT=latarcyrheb-sun16
			LANG="zh_CN.UTF-8"
			SYSFONT="latarcyrheb-sun16"
			SUPPORTED="zh_CN.UTF-8:zh_CN:zh"
		EOF
	elif [ "$release" = "7" ]; then
		localectl set-locale LANG=zh_CN.utf8
		localectl set-keymap cn
		localectl set-x11-keymap cn
	fi
	timedatectl set-timezone Asia/Shanghai
	crontab -l > conf
	echo "*/5 * * * * /usr/sbin/ntpdate -u asia.pool.ntp.org >> /tmp/tmp.txt" >> conf 
	crontab conf && rm -f conf
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
	[ -f /etc/sysconfig/selinux ] && { sed -i 's/^SELINUX=.*/#&/;s/^SELINUXTYPE=.*/#&/;/SELINUX=.*/a SELINUX=disabled' /etc/sysconfig/selinux
		/usr/sbin/setenforce 0; }
	[ -f /etc/selinux/config ] && { sed -i 's/^SELINUX=.*/#&/;s/^SELINUXTYPE=.*/#&/;/SELINUX=.*/a SELINUX=disabled' /etc/selinux/config
		/usr/sbin/setenforce 0; }
}

dockerINSTALL() {
	curl -fsSL https://get.docker.com/ | sh
	systemctl enable docker && systemctl start docker
	sudo curl -L "https://github.com/docker/compose/releases/download/v2.2.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x  /usr/local/bin/docker-compose
}

setWGET() {
	mv /usr/share/locale/zh_CN/LC_MESSAGES/wget.{mo,mo.back}
	msgunfmt /usr/share/locale/zh_CN/LC_MESSAGES/wget.mo.back -o - | sed 's/eta(英国中部时间)/ETA/' | msgfmt - -o /usr/share/locale/zh_CN/LC_MESSAGES/wget.mo
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
	setWGET
}

main ${@} && [ -x /bin/systeminfo ] && clear; systeminfo all
rm -rf $0
