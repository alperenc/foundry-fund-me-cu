-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(ALCHEMY_SEPOLIA_RPC_URL) --account metamask_2 --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv