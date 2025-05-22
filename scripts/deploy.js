const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Decentralized Social Network...");
  
  // Get the ContractFactory and Signers
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  
  // Deploy the contract
  const DecentralizedSocialNetwork = await ethers.getContractFactory("DecentralizedSocialNetwork");
  const socialNetwork = await DecentralizedSocialNetwork.deploy();
  
  await socialNetwork.deployed();
  
  console.log("DecentralizedSocialNetwork deployed to:", socialNetwork.address);
  console.log("Transaction hash:", socialNetwork.deployTransaction.hash);
  
  // Verify deployment
  console.log("Verifying deployment...");
  const totalUsers = await socialNetwork.totalUsers();
  const totalPosts = await socialNetwork.totalPosts();
  
  console.log("Initial total users:", totalUsers.toString());
  console.log("Initial total posts:", totalPosts.toString());
  console.log("Deployment successful!");
  
  // Save deployment info
  console.log("\n=== Deployment Summary ===");
  console.log(`Network: ${network.name}`);
  console.log(`Contract Address: ${socialNetwork.address}`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Gas Used: ${socialNetwork.deployTransaction.gasLimit?.toString() || 'N/A'}`);
  console.log("============================");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
