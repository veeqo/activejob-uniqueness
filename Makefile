.PHONY: build up down test shell clean restart logs help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker images
	docker-compose build

up: ## Start all services
	docker-compose up

down: ## Stop and remove all containers
	docker-compose down

test: ## Run all specs
	docker-compose run --rm app bundle exec rspec

shell: ## Open a shell in the app container
	docker-compose run --rm app /bin/bash

clean: ## Remove containers, volumes, and images
	docker-compose down -v --rmi local

restart: down up ## Restart all services

logs: ## Follow logs from all services
	docker-compose logs -f

test-file: ## Run a specific test file (usage: make test-file FILE=spec/path/to/file_spec.rb)
	docker-compose run --rm app bundle exec rspec $(FILE)

bundle-install: ## Install/update gems
	docker-compose run --rm app bundle install

bundle-update: ## Update gems
	docker-compose run --rm app bundle update

rubocop: ## Run rubocop
	docker-compose run --rm app bundle exec rubocop

rubocop-fix: ## Run rubocop with auto-correct
	docker-compose run --rm app bundle exec rubocop -A
