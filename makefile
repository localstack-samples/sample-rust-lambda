.PHONY: all test clean build package delete-lambda create-lambda update-lambda get-lambda-url it-again

-include .env-gdc
-include .env-gdc-local

LAMBDA_URL = $(shell aws lambda get-function-url-config --function-name grpc-rust-test | jq -rc '.FunctionUrl')
LAMBDA_NAME = grpc-rust-test
ZIP_FILE = lambda.zip
ARG_TARGET = aarch64-unknown-linux-gnu
BIN_NAME = lambda
# replace with your AWS account number
AWS_ACCT=000000000000
LAMBDA_ROLE_NAME = $(LAMBDA_NAME)-role

export ARCHITECTURE=$(shell uname -m | sed 's/amd64/x86_64/')
ifneq ($(ARCHITECTURE), x86_64)
	export ARCHITECTURE := aarch64
endif
export MACHINE=$(shell uname -s | sed 's/Darwin/macos/')
ifeq ($(MACHINE), Linux)
	export MACHINE = linux
else ifeq ($(MACHINE), Win)
	export MACHINE = windows
endif

all: package

clean:
	rm -f *.zip

build: clean
	cargo zigbuild --release --target $(ARG_TARGET).2.34 --bin $(BIN_NAME)

package: build
	cp ./target/$(ARG_TARGET)/release/$(BIN_NAME) ./bootstrap
	zip $(ZIP_FILE) bootstrap
	rm ./bootstrap

init-rust:
	rm -f /usr/local/bin/zig
	rm -rf /usr/local/lib/zig
	curl https://ziglang.org/builds/zig-${MACHINE}-${ARCHITECTURE}-0.12.0-dev.2825+dd1fc1cb8.tar.xz | tar -xJ
	mv zig-${MACHINE}-${ARCHITECTURE}-0.12.0-dev.2825+dd1fc1cb8/zig /usr/local/bin/zig
	mkdir -p /usr/local/lib/zig
	mv zig-${MACHINE}-${ARCHITECTURE}-0.12.0-dev.2825+dd1fc1cb8/lib/* /usr/local/lib/zig
	rm -rf zig-${MACHINE}-${ARCHITECTURE}-0.12.0-dev.2825+dd1fc1cb8
	rustup target add aarch64-unknown-linux-gnu
	rustup target add x86_64-unknown-linux-gnu
	cargo install cargo-zigbuild

delete-lambda-role:
	aws iam detach-role-policy --role-name $(LAMBDA_ROLE_NAME) --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
	aws iam delete-role --role-name $(LAMBDA_ROLE_NAME)

delete-lambda-function:
	aws lambda delete-function --function-name $(LAMBDA_NAME)

delete-lambda: delete-lambda-function delete-lambda-role

create-lambda-role:
	aws iam create-role --role-name $(LAMBDA_ROLE_NAME) --assume-role-policy-document file://lambda-role-trust-policy.json
	aws iam attach-role-policy --role-name $(LAMBDA_ROLE_NAME) --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

create-lambda-function: package
	aws lambda create-function --function-name $(LAMBDA_NAME) \
	  --architectures arm64 \
	  --handler doesnt.matter \
	  --zip-file fileb://./$(ZIP_FILE) \
	  --runtime provided.al2023 \
	  --role arn:aws:iam::$(AWS_ACCT):role/$(LAMBDA_ROLE_NAME) \
	  --environment "Variables={RUST_BACKTRACE=1, RUST_LOG=INFO}"
	sleep 5
	aws lambda create-function-url-config --function-name $(LAMBDA_NAME) \
  		--auth-type NONE
	aws lambda add-permission \
		--function-name $(LAMBDA_NAME) \
		--function-url-auth-type NONE \
		--statement-id FunctionURLAllowPublicAccess \
		--action lambda:InvokeFunctionUrl \
		--principal '*'

update-lambda:
	aws lambda update-function-code --function-name $(LAMBDA_NAME) --zip-file fileb://$(ZIP_FILE) --no-cli-pager

get-lambda-url:
	curl -X POST $(LAMBDA_URL) \
	-H 'Content-Type: application/json' \
	-d '{"first_name": "lstack"}'

it-again: all update-lambda get-lambda-url

test:
	LAMBDA_INVOKE_URL=$(LAMBDA_URL) cargo test

start-localstack:
	@ARCHITECTURE=$(ARCHITECTURE); \
    if [ "$$ARCHITECTURE" = "x86_64" ]; then \
        cd devops-tooling && docker compose -f docker-compose.localstack.yml -f docker-compose.amd64_localstack.yml -p $(APP_NAME) up $(DOCKER_COMPOSE_FLAGS); \
    else \
        cd devops-tooling && docker compose -f docker-compose.localstack.yml -p $(APP_NAME) up $(DOCKER_COMPOSE_FLAGS); \
    fi
