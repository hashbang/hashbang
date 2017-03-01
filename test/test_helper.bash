gen_ssh_key(){
	OUT=$1
	[ -z $OUT ] && OUT=sshkey
	if [ ! -f /tmp/$OUT ]; then
		ssh-keygen -b 2048 -t rsa -f /tmp/$OUT -q -N ""
	fi
}

import_ssh_key(){
	docker \
		exec \
		-i hashbang_shellbox_1 \
		bash -c 'mkdir -p /root/.ssh/ && cat >> /root/.ssh/authorized_keys' \
			< /tmp/sshkey.pub
}

setup_root_ssh(){
	gen_ssh_key
	import_ssh_key
}

docker_exec(){
	docker \
		exec \
		-i hashbang_shellbox_1 \
		$* <&0
}

ssh_exec(){
	ssh \
		-p 22 \
        -a \
		-i /tmp/sshkey \
		-o UserKnownHostsFile=/dev/null \
		-o StrictHostKeyChecking=no \
		$*
}

ssh_test(){
	echo quit | telnet $1 22 | grep Connected
}
