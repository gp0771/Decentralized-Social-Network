const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("\n🚀 Starting Decentralized Social Network Deployment...\n");
  
  try {
    // Get network information
    const network = await ethers.provider.getNetwork();
    console.log(`📡 Network: ${network.name} (Chain ID: ${network.chainId})`);
    
    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log(`👤 Deployer Address: ${deployer.address}`);
    
    // Check deployer balance
    const balance = await deployer.getBalance();
    const balanceInEth = ethers.utils.formatEther(balance);
    console.log(`💰 Deployer Balance: ${balanceInEth} ETH`);
    
    if (balance.lt(ethers.utils.parseEther("0.01"))) {
      console.warn("⚠️  Warning: Low balance detected. Make sure you have enough funds for deployment.");
    }
    
    console.log("\n" + "=".repeat(50));
    console.log("🔨 DEPLOYING CONTRACT");
    console.log("=".repeat(50));
    
    // Get the contract factory
    const DecentralizedSocialNetwork = await ethers.getContractFactory("DecentralizedSocialNetwork");
    
    // Estimate gas for deployment
    const deploymentData = DecentralizedSocialNetwork.bytecode;
    const estimatedGas = await ethers.provider.estimateGas({
      data: deploymentData
    });
    
    console.log(`⛽ Estimated Gas: ${estimatedGas.toString()}`);
    
    // Get current gas price
    const gasPrice = await ethers.provider.getGasPrice();
    console.log(`💸 Gas Price: ${ethers.utils.formatUnits(gasPrice, "gwei")} gwei`);
    
    const estimatedCost = estimatedGas.mul(gasPrice);
    console.log(`💵 Estimated Deployment Cost: ${ethers.utils.formatEther(estimatedCost)} ETH`);
    
    console.log("\n📦 Deploying DecentralizedSocialNetwork contract...");
    
    // Deploy the contract with gas settings
    const socialNetwork = await DecentralizedSocialNetwork.deploy({
      gasLimit: estimatedGas.add(50000), // Add buffer for safety
      gasPrice: gasPrice
    });
    
    console.log("⏳ Waiting for deployment transaction...");
    
    // Wait for deployment
    await socialNetwork.deployed();
    
    console.log("\n" + "=".repeat(50));
    console.log("✅ DEPLOYMENT SUCCESSFUL");
    console.log("=".repeat(50));
    
    console.log(`📋 Contract Address: ${socialNetwork.address}`);
    console.log(`🔗 Transaction Hash: ${socialNetwork.deployTransaction.hash}`);
    console.log(`⛽ Gas Used: ${socialNetwork.deployTransaction.gasLimit?.toString() || 'N/A'}`);
    console.log(`🏷️  Block Number: ${socialNetwork.deployTransaction.blockNumber || 'Pending'}`);
    
    // Verify the deployment by calling view functions
    console.log("\n" + "=".repeat(50));
    console.log("🔍 VERIFYING DEPLOYMENT");
    console.log("=".repeat(50));
    
    try {
      const totalUsers = await socialNetwork.totalUsers();
      const totalPosts = await socialNetwork.totalPosts();
      
      console.log(`👥 Initial Total Users: ${totalUsers.toString()}`);
      console.log(`📄 Initial Total Posts: ${totalPosts.toString()}`);
      console.log("✅ Contract verification successful!");
      
    } catch (error) {
      console.error("❌ Contract verification failed:", error.message);
    }
    
    // Save deployment information
    const deploymentInfo = {
      network: network.name,
      chainId: network.chainId,
      contractAddress: socialNetwork.address,
      deployerAddress: deployer.address,
      transactionHash: socialNetwork.deployTransaction.hash,
      blockNumber: socialNetwork.deployTransaction.blockNumber,
      gasUsed: socialNetwork.deployTransaction.gasLimit?.toString(),
      gasPrice: gasPrice.toString(),
      deploymentCost: estimatedCost.toString(),
      timestamp: new Date().toISOString(),
      contractName: "DecentralizedSocialNetwork"
    };
    
    // Create deployments directory if it doesn't exist
    const deploymentsDir = path.join(__dirname, "../deployments");
    if (!fs.existsSync(deploymentsDir)) {
      fs.mkdirSync(deploymentsDir, { recursive: true });
    }
    
    // Save deployment info to file
    const fileName = `${network.name}_${Date.now()}.json`;
    const filePath = path.join(deploymentsDir, fileName);
    
    fs.writeFileSync(filePath, JSON.stringify(deploymentInfo, null, 2));
    console.log(`💾 Deployment info saved to: ${filePath}`);
    
    // Generate ABI file for frontend integration
    const artifactPath = path.join(__dirname, "../artifacts/contracts/DecentralizedSocialNetwork.sol/DecentralizedSocialNetwork.json");
    if (fs.existsSync(artifactPath)) {
      const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
      const abiPath = path.join(deploymentsDir, `DecentralizedSocialNetwork_ABI.json`);
      
      const abiInfo = {
        contractName: "DecentralizedSocialNetwork",
        contractAddress: socialNetwork.address,
        network: network.name,
        chainId: network.chainId,
        abi: artifact.abi
      };
      
      fs.writeFileSync(abiPath, JSON.stringify(abiInfo, null, 2));
      console.log(`📜 ABI file saved to: ${abiPath}`);
    }
    
    console.log("\n" + "=".repeat(50));
    console.log("📊 DEPLOYMENT SUMMARY");
    console.log("=".repeat(50));
    
    console.log(`🌐 Network: ${network.name}`);
    console.log(`🔗 Chain ID: ${network.chainId}`);
    console.log(`📋 Contract: DecentralizedSocialNetwork`);
    console.log(`📍 Address: ${socialNetwork.address}`);
    console.log(`👤 Deployer: ${deployer.address}`);
    console.log(`💰 Cost: ${ethers.utils.formatEther(estimatedCost)} ETH`);
    console.log(`⏰ Time: ${new Date().toLocaleString()}`);
    
    // Network-specific explorer links
    let explorerUrl = "";
    switch (network.chainId) {
      case 1115: // Core Testnet 2
        explorerUrl = `https://scan.test2.btcs.network/address/${socialNetwork.address}`;
        break;
      case 1: // Ethereum Mainnet
        explorerUrl = `https://etherscan.io/address/${socialNetwork.address}`;
        break;
      case 5: // Goerli Testnet
        explorerUrl = `https://goerli.etherscan.io/address/${socialNetwork.address}`;
        break;
      case 137: // Polygon Mainnet
        explorerUrl = `https://polygonscan.com/address/${socialNetwork.address}`;
        break;
      default:
        explorerUrl = "N/A";
    }
    
    if (explorerUrl !== "N/A") {
      console.log(`🔍 Explorer: ${explorerUrl}`);
    }
    
    console.log("\n" + "=".repeat(50));
    console.log("🎯 NEXT STEPS");
    console.log("=".repeat(50));
    
    console.log("1. 📋 Copy the contract address for frontend integration");
    console.log("2. 🔍 Verify the contract on the block explorer (if supported)");
    console.log("3. 🧪 Test the contract functions using Hardhat console or frontend");
    console.log("4. 📱 Update your frontend configuration with the new contract address");
    console.log("5. 🚀 Start building your decentralized social network!");
    
    // Example interaction code
    console.log("\n" + "=".repeat(50));
    console.log("💡 EXAMPLE INTERACTIONS");
    console.log("=".repeat(50));
    
    console.log("// Register a user");
    console.log(`await contract.registerUser("alice", "Blockchain enthusiast");`);
    console.log("");
    console.log("// Create a post");
    console.log(`await contract.createPost("Hello decentralized world!");`);
    console.log("");
    console.log("// Like a post");
    console.log(`await contract.toggleLike(1);`);
    console.log("");
    console.log("// Get user info");
    console.log(`const user = await contract.getUser("0x...");`);
    console.log("");
    console.log("// Get latest posts");
    console.log(`const posts = await contract.getLatestPosts(10);`);
    
    console.log("\n🎉 Deployment completed successfully!");
    
  } catch (error) {
    console.error("\n❌ Deployment failed!");
    console.error("Error:", error.message);
    
    if (error.code === "INSUFFICIENT_FUNDS") {
      console.error("\n💡 Solution: Add more funds to your deployer account");
    } else if (error.code === "NETWORK_ERROR") {
      console.error("\n💡 Solution: Check your network connection and RPC URL");
    } else if (error.message.includes("gas")) {
      console.error("\n💡 Solution: Try increasing gas limit or gas price");
    }
    
    process.exit(1);
  }
}

// Handle script termination
process.on('SIGINT', () => {
  console.log('\n\n⚠️  Deployment interrupted by user');
  process.exit(0);
});

process.on('uncaughtException', (error) => {
  console.error('\n❌ Uncaught Exception:', error.message);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('\n❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Run the deployment
main()
  .then(() => {
    console.log("\n✨ Script execution completed");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n💥 Script failed:", error);
    process.exit(1);
  });
