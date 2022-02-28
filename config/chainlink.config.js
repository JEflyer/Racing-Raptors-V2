const { ethers } = require("hardhat");

const config = {
    //Hardhat local network
    //MockData (It won't work)
    31337: {
        name: "hardhat",
        keyHash: "0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4",
        fee: "0.1",
        fundAmount: "10000000000000000000",
    },
    // Polygon Mumbai
  80001: {
    name: "mumbai",
    linkToken: "0xb0897686c545045aFc77CF20eC7A532E3120E0F1",
    vrfCoordinator: "0x3d2341ADb2D31f1c5530cDC622016af293177AE0",
    keyHash:
      "0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da",
    fee: "0.0001",
  },
  // Polygon Mainnet
  137: {
    name: "polygon",
    linkToken: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
    vrfCoordinator: "0x8C7382F9D8f56b33781fE506E897a4F1e2d17255",
    keyHash:
      "0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4",
    fee: "0.0001",
  },
  // Ethereum Mainnet
  1: {
    name: "mainnet",
    linkToken: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
    vrfCoordinator: "0xf0d54349aDdcf704F77AE15b96510dEA15cb7952",
    keyHash:
      "0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445",
    fee: "2",
  },
  // Rinkeby
  4: {
    name: "rinkeby",
    linkToken: "0x01BE23585060835E02B77ef475b0Cc51aA1e0709",
    vrfCoordinator: "0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B",
    keyHash:
      "0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311",
    fee: "0.1",
    fundAmount: "2000000000000000000",
  },
  // Kovan
  42: {
    name: "kovan",
    linkToken: "0xa36085F69e2889c224210F603D836748e7dC0088",
    vrfCoordinator: "0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9",
    keyHash:
      "0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4",
    fee: 0.1,
  },
};

const autoFundCheck = async (
    contractAddr,
    networkName,
    linkTokenAddress,
    additionalMessage
) => {
    const chainId = getChainId();
    console.log("Checking to see if the contract can be auto-funded with link: ");
    const amount = config[chainId].fundAmount;
    //check to see if user has enough link
    const accounts = await ethers.getSigners();
    const signer = accounts[0];
    const LinkToken = await ethers.getContractFactory("LinkToken");
    const linkTokenContract = new ethers.Contract(linkTokenAddress, LinkToken.interface, signer);
    const balanceHex = await linkTokenContract.balanceOf(signer.address);
    const balance = await ethers.BigNumber.from(balanceHex._hex).toString();
    const contractBalanceHex = await linkTokenContract.balanceOf(contractAddr);
    const contractBalance= await ethers.BigNumber.from(contractBalanceHex._hex).toString();
    if(balance > amount && amount > 0 && contractBalance < amount) {return true;}
    else{
        console.log("Account doesn't have enough LINK to fund contract, or you're deploying to a nework where auto funding isn't done by default");
        console.log("Please obtain LINK via the faucet at https://" + networkName+".chain.link/, then run the following command to fund contract with LINK:");
    
        console.log("npx hardhat fund-link --contract " +
            contractAddr +
            " --network " +
            networkName + additionalMessage
        );

        return false;
    }
};

module.exports = {
    config,
    autoFundCheck,
};