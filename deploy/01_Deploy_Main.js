const {config} = require("../config/chainlink.config.js");
const fs = require("fs");
const hre = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = async({getNamedAccounts, deployments, getChainId, ethers}) => {
    const {deploy, get, log} = deployments;
    const {deployer, user2, user3, payee1, payee2, payee3, user4, user5} = await getNamedAccounts();
    const chainId = await getChainId();
    let linkToken;
    let linkTokenAddress;
    let VRFCoordinatorMock;
    let vrfCoordinatorAddress;
    let additionalMessage= "";
    let keyHash;
    let fee;
    let rewardedAddresses = [deployer, user2, user3, payee1, payee2, payee3, user4, user5];
    let paymentsTo= [payee1,payee2,payee3];
    let communityWallet= user3;

    if(chainId == 31337) {

        linkToken = await get("LinkToken");
        VRFCoordinatorMock = await get("VRFCoordinatorMock");
        linkTokenAddress = linkToken.address;
        vrfCoordinatorAddress = VRFCoordinatorMock.address;        
        additionalMessage = " --linkAddress " + linkTokenAddress + " --fundamount " + config[chainId].fundAmount;
    }else {
        linkTokenAddress = config[chainId].linkToken;
        vrfCoordinatorAddress = config[chainId].vrfCoordinator;
    }

    keyHash = config[chainId].keyHash;
    fee = config[chainId].fee;

    const minter = await deploy("MinterV3", {
        from: deployer,
        args: [
            rewardedAddresses,
            paymentsTo,
            vrfCoordinatorAddress,
            linkTokenAddress,
            keyHash,
            ethers.utils.parseUnits(fee, 18),
        ],
        log: true,
    });

    

    await minter.wait;

    

    const game = await deploy("GameV3", {
        from: deployer,
        args: [
            minter.address,
            communityWallet,
            ethers.utils.parseUnits("1", 15),
            vrfCoordinatorAddress,
            linkTokenAddress,
            keyHash,
            ethers.utils.parseUnits(fee, 18),
            1000,
        ],
        log: true,
    });

    await game.wait;

    await sleep(120000)


    // ALREADY VERIFIED BUT WORKING
    await hre.run("verify:verify",{
        network: "rinkeby",
        address: minter.address,
        constructorArguments:[
            rewardedAddresses,
            paymentsTo,
            vrfCoordinatorAddress,
            linkTokenAddress,
            keyHash,
            ethers.utils.parseUnits(fee, 18),
        ]
    })
    
    // ALREADY VERIFIED BUT WORKING
    await hre.run("verify:verify",{
        network: "rinkeby",
        address: game.address,
        constructorArguments:[
            minter.address,
            communityWallet,
            ethers.utils.parseUnits("1", 15),
            vrfCoordinatorAddress,
            linkTokenAddress,
            keyHash,
            ethers.utils.parseUnits(fee, 18),
            1000,
        ]
    })


    log("Run the following command to fund minter contract with LINK:");
    log(
        "npx hardhat fund-link --contract " +
        minter.address +
        " --network " +
        config[chainId].name +
        additionalMessage
    );
    log("-------------------------------------------------------");
    log("Run the following command to fund game contract with LINK:");
    log(
        "npx hardhat fund-link --contract " +
        game.address +
        " --network " +
        config[chainId].name +
        additionalMessage
    );

};

module.exports.tags = ["all", "main"];