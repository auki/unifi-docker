.PHONY: build test

build:
	docker build -t auki/unifi .

test:
	docker-compose build && docker-compose up
