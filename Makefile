-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil zktest

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_ZKSYNC_LOCAL_KEY := 0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

zkbuild :; forge build --zksync

test :; forge test

zktest :; foundryup-zksync && forge test --zksync && foundryup

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

zk-anvil :; npx zksync-cli dev start

# Default network arguments for localhost (Anvil)
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

# If the network is Sepolia, overwrite the network args
ifeq ($(NETWORK),sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# Targets
deploy:
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(NETWORK_ARGS)

# Custom deploy targets for localhost (Anvil) and Sepolia
deploy-localhost:
	@$(MAKE) deploy NETWORK=localhost

deploy-anvil:
	@$(MAKE) deploy NETWORK=localhost

deploy-sepolia:
	@$(MAKE) deploy NETWORK=sepolia


# As of writing, the Alchemy zkSync RPC URL is not working correctly 
deploy-zk:
	forge create src/FundMe.sol:FundMe --rpc-url http://127.0.0.1:8011 --private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) --constructor-args $(shell forge create test/mock/MockV3Aggregator.sol:MockV3Aggregator --rpc-url http://127.0.0.1:8011 --private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) --constructor-args 8 200000000000 --legacy --zksync | grep "Deployed to:" | awk '{print $$3}') --legacy --zksync

deploy-zk-sepolia:
	forge create src/FundMe.sol:FundMe --rpc-url ${ZKSYNC_SEPOLIA_RPC_URL} --account default --constructor-args 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF --legacy --zksync


# Default sender addresses for different networks
DEFAULT_SENDER_ADDRESS := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Select the correct sender and RPC URL based on the network
ifeq ($(NETWORK),localhost)
	SENDER_ADDRESS := $(DEFAULT_SENDER_ADDRESS)
	PRIVATE_KEY := $(DEFAULT_ANVIL_KEY)
	RPC_URL := $(ANVIL_RPC_URL)
endif
ifeq ($(NETWORK),sepolia)
	SENDER_ADDRESS := $(SEPOLIA_SENDER_ADDRESS)
	PRIVATE_KEY := $(PRIVATE_KEY)
	RPC_URL := $(SEPOLIA_RPC_URL)
endif
# else
# 	$(error "Unsupported network: $(NETWORK)")
# endif

# For deploying Interactions.s.sol:FundFundMe
fund:
	@forge script script/Interactions.s.sol:FundFundMe --rpc-url $(RPC_URL) --sender $(SENDER_ADDRESS) --private-key $(PRIVATE_KEY) --broadcast -vvvv

# Custom fund targets for different networks
fund-localhost:
	@$(MAKE) fund NETWORK=localhost

fund-anvil:
	@$(MAKE) fund NETWORK=localhost

fund-sepolia:
	@$(MAKE) fund NETWORK=sepolia

# For deploying Interactions.s.sol:WithdrawFundMe
withdraw:
	@forge script script/Interactions.s.sol:WithdrawFundMe --rpc-url $(RPC_URL) --sender $(SENDER_ADDRESS) --private-key $(PRIVATE_KEY) --broadcast -vvvv

# Custom withdraw targets for different networks
withdraw-localhost:
	@$(MAKE) withdraw NETWORK=localhost

withdraw-anvil:
	@$(MAKE) withdraw NETWORK=localhost

withdraw-sepolia:
	@$(MAKE) withdraw NETWORK=sepolia
