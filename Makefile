all:

test:
	docker-compose up -d
	docker exec -it hashbang_test_1 bats test.bats
	docker-compose down

.PHONY: all test
