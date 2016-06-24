load test_helper

setup(){
    setup_root_ssh
}

teardown(){
    echo
}

@test "Can execute ssh command in shellbox" {
    run ssh_exec root@shellbox ls
    [ "$status" -eq 0 ]
}

@test "Can ssh to signup" {
    run ssh_test signup
    [ "$status" -eq 0 ]
}
