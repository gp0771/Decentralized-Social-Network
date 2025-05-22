require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

// Validate required environment variables
const requiredEnvVars = ["PRIVATE_KEY"];
const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
  console.warn(`⚠️  Warning: Missing environment variables: ${missingEnvVars.join(", ")}`);
  console.warn("Please check your .env file and ensure all required variables are set.");
}

// Network configuration helper function
function createNetworkConfig(url, chainId, accounts = []) {
  const config = {
    url,
    chainId,
    accounts: accounts.length > 0 ? accounts : (process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []),
  };
  
  // Add gas configuration based on network
  switch (chainId) {
    case 1115: // Core Testnet 2
      config.gasPrice = 20000000000; // 20 gwei
      config.gas = 8000000; // 8M gas limit
      break;
    case 1116: // Core Mainnet
      config.gasPrice = 25000000000; // 25 gwei
      config.gas = 8000000;
      break;
    case 1: // Ethereum Mainnet
      config.gasPrice = "auto";
      config.gas = "auto";
      break;
    case 5: // Goerli Testnet
      config.gasPrice = 20000000000; // 20 gwei
      config.gas = 8000000;
      break;
    case 137: // Polygon Mainnet
      config.gasPrice = 30000000000; // 30 gwei
      config.gas = 8000000;
      break;
    case 80001: // Polygon Mumbai
      config.gasPrice = 20000000000; // 20 gwei
      config.gas = 8000000;
      break;
    case 56: // BSC Mainnet
      config.gasPrice = 5000000000; // 5 gwei
      config.gas = 8000000;
      break;
    case 97: // BSC Testnet
      config.gasPrice = 10000000000; // 10 gwei
      config.gas = 8000000;
      break;
    default:
      config.gasPrice = 20000000000; // 20 gwei default
      config.gas = 8000000;
  }
  
  return config;
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yul: true,
          yulDetails: {
            stackAllocation: true,
            optimizerSteps: "dhfoDgvulfnTUtnIf"
          }
        }
      },
      viaIR: true, // Enable intermediate representation for better optimization
      metadata: {
        bytecodeHash: "none" // Remove metadata hash for deterministic builds
      },
      outputSelection: {
        "*": {
          "*": ["storageLayout"] // Include storage layout for upgradeable contracts
        }
      }
    }
  },
  
  networks: {
    // Local development network
    hardhat: {
      chainId: 31337,
      gas: 12000000,
      gasPrice: 20000000000,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
        count: 20,
        accountsBalance: "10000000000000000000000" // 10,000 ETH per account
      },
      mining: {
        auto: true,
        interval: 0 // Mine blocks instantly
      },
      forking: process.env.FORK_URL ? {
        url: process.env.FORK_URL,
        blockNumber: process.env.FORK_BLOCK_NUMBER ? parseInt(process.env.FORK_BLOCK_NUMBER) : undefined
      } : undefined
    },
    
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
      gas: 12000000,
      gasPrice: 20000000000,
      timeout: 60000
    },
    
    // Core Network - Primary deployment target
    core_testnet2: createNetworkConfig(
      process.env.CORE_TESTNET2_RPC_URL || "https://rpc.test2.btcs.network",
      1115
    ),
    
    core_mainnet: createNetworkConfig(
      process.env.CORE_MAINNET_RPC_URL || "https://rpc.coredao.org",
      1116
    ),
    
    // Ethereum Networks
    ethereum: createNetworkConfig(
      process.env.ETHEREUM_RPC_URL || `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      1
    ),
    
    goerli: createNetworkConfig(
      process.env.GOERLI_RPC_URL || `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
      5
    ),
    
    sepolia: createNetworkConfig(
      process.env.SEPOLIA_RPC_URL || `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      11155111
    ),
    
    // Polygon Networks
    polygon: createNetworkConfig(
      process.env.POLYGON_RPC_URL || "https://polygon-rpc.com",
      137
    ),
    
    mumbai: createNetworkConfig(
      process.env.MUMBAI_RPC_URL || "https://rpc-mumbai.maticvigil.com",
      80001
    ),
    
    // Binance Smart Chain
    bsc: createNetworkConfig(
      process.env.BSC_RPC_URL || "https://bsc-dataseed1.binance.org",
      56
    ),
    
    bsc_testnet: createNetworkConfig(
      process.env.BSC_TESTNET_RPC_URL || "https://data-seed-prebsc-1-s1.binance.org:8545",
      97
    ),
    
    // Arbitrum Networks
    arbitrum: createNetworkConfig(
      process.env.ARBITRUM_RPC_URL || "https://arb1.arbitrum.io/rpc",
      42161
    ),
    
    arbitrum_goerli: createNetworkConfig(
      process.env.ARBITRUM_GOERLI_RPC_URL || "https://goerli-rollup.arbitrum.io/rpc",
      421613
    ),
    
    // Optimism Networks
    optimism: createNetworkConfig(
      process.env.OPTIMISM_RPC_URL || "https://mainnet.optimism.io",
      10
    ),
    
    optimism_goerli: createNetworkConfig(
      process.env.OPTIMISM_GOERLI_RPC_URL || "https://goerli.optimism.io",
      420
    ),
    
    // Avalanche Networks
    avalanche: createNetworkConfig(
      process.env.AVALANCHE_RPC_URL || "https://api.avax.network/ext/bc/C/rpc",
      43114
    ),
    
    fuji: createNetworkConfig(
      process.env.FUJI_RPC_URL || "https://api.avax-test.network/ext/bc/C/rpc",
      43113
    )
  },
  
  // Contract verification configuration
  etherscan: {
    apiKey: {
      // Core Network
      core_testnet2: process.env.CORE_TESTNET_API_KEY || "your-core-testnet-api-key",
      core_mainnet: process.env.CORE_MAINNET_API_KEY || "your-core-mainnet-api-key",
      
      // Ethereum
      mainnet: process.env.ETHERSCAN_API_KEY,
      goerli: process.env.ETHERSCAN_API_KEY,
      sepolia: process.env.ETHERSCAN_API_KEY,
      
      // Polygon
      polygon: process.env.POLYGONSCAN_API_KEY,
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
      
      // BSC
      bsc: process.env.BSCSCAN_API_KEY,
      bscTestnet: process.env.BSCSCAN_API_KEY,
      
      // Arbitrum
      arbitrumOne: process.env.ARBISCAN_API_KEY,
      arbitrumGoerli: process.env.ARBISCAN_API_KEY,
      
      // Optimism
      optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY,
      optimisticGoerli: process.env.OPTIMISTIC_ETHERSCAN_API_KEY,
      
      // Avalanche
      avalanche: process.env.SNOWTRACE_API_KEY,
      avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY
    },
    
    customChains: [
      {
        network: "core_testnet2",
        chainId: 1115,
        urls: {
          apiURL: "https://api.test2.btcs.network/api",
          browserURL: "https://scan.test2.btcs.network"
        }
      },
      {
        network: "core_mainnet",
        chainId: 1116,
        urls: {
          apiURL: "https://openapi.coredao.org/api",
          browserURL: "https://scan.coredao.org"
        }
      }
    ]
  },
  
  // Gas reporting configuration
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    gasPrice: 21,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    token: "ETH",
    gasPriceApi: "https://api.etherscan.io/api?module=proxy&action=eth_gasPrice",
    showTimeSpent: true,
    showMethodSig: true,
    maxMethodDiff: 10,
    outputFile: "gas-report.txt",
    noColors: false,
    rst: true,
    rstTitle: "Gas Usage Report",
    excludeContracts: ["Migrations"]
  },
  
  // Mocha test configuration
  mocha: {
    timeout: 60000, // 60 seconds
    bail: false, // Don't stop on first test failure
    allowUncaught: false,
    reporter: process.env.MOCHA_REPORTER || "spec",
    reporterOptions: {
      output: "test-results.json"
    }
  },
  
  // Contract size analysis
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: process.env.CONTRACT_SIZER === "true",
    strict: true,
    only: ["DecentralizedSocialNetwork"]
  },
  
  // Code coverage configuration
  solidity_coverage: {
    skipFiles: [
      "test/",
      "scripts/",
      "migrations/"
    ],
    measureStatementCoverage: true,
    measureBranchCoverage: true,
    measureFunctionCoverage: true,
    measureLineCoverage: true,
    istanbulReporter: ["html", "lcov", "text", "json"],
    providerOptions: {
      mnemonic: "test test test test test test test test test test test junk"
    }
  },
  
  // Paths configuration
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
    deploy: "./scripts",
    deployments: "./deployments"
  },
  
  // Default network for deployment
  defaultNetwork: "hardhat",
  
  // Warnings configuration
  warnings: {
    "contracts/**/*": {
      "code-size": "error",
      "unused-param": "warning",
      "unused-var": "warning",
      "func-mutability": "warning"
    }
  },
  
  // External contracts (for testing and forking)
  external: process.env.HARDHAT_FORK ? {
    contracts: [
      {
        artifacts: "node_modules/@openzeppelin/contracts/build/contracts"
      }
    ]
  } : undefined,
  
  // Docgen configuration for documentation
  docgen: {
    path: "./docs",
    clear: true,
    runOnCompile: false,
    only: ["contracts/DecentralizedSocialNetwork.sol"]
  },
  
  // Dependency compiler configuration
  dependencyCompiler: {
    paths: [
      "@openzeppelin/contracts/token/ERC20/ERC20.sol",
      "@openzeppelin/contracts/access/Ownable.sol"
    ]
  }
};

// Export helper functions for scripts
module.exports.createNetworkConfig = createNetworkConfig;

// Log configuration on startup
if (process.env.NODE_ENV !== "test") {
  console.log("🔧 Hardhat configuration loaded");
  console.log(`📁 Project root: ${__dirname}`);
  console.log(`🌐 Default network: ${module.exports.defaultNetwork}`);
  
  if (process.env.PRIVATE_KEY) {
    console.log("✅ Private key configured");
  } else {
    console.log("⚠️  No private key found in environment variables");
  }
  
  const enabledFeatures = [];
  if (process.env.REPORT_GAS === "true") enabledFeatures.push("Gas Reporter");
  if (process.env.CONTRACT_SIZER === "true") enabledFeatures.push("Contract Sizer");
  if (enabledFeatures.length > 0) {
    console.log(`🎛️  Enabled features: ${enabledFeatures.join(", ")}`);
  }
}
