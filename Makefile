.PHONY: build test

build:
	docker build -t auki/unifi .

test: build
	docker run -p 8443:8443 auki/unifi
	#docker-compose build && docker-compose up
