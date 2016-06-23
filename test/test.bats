load test_helper

setup(){
    setup_root_ssh
}

teardown(){
    echo
}

@test "Can execute ssh command in shellbox container" {
    run ssh_exec root@shellbox ls
	[ "$status" -eq 0 ]
}
