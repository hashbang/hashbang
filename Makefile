all:

test:
	git submodule update --init --recursive
	docker-compose build
	docker-compose -f docker-compose.yml -f ./test/docker-compose.test.yml up -d
	docker exec -it hashbang_test_1 bats test.bats
	docker-compose down --remove-orphans

.PHONY: all test
