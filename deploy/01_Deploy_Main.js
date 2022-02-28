const {config} = require("../config/chainlink.config.js");
const fs = require("fs");

module.exports = async({getNamedAccounts, deployments, getChainId, ethers}) => {
    const {deploy, get, log} = deployments;
    const {deployer, user2, user3, payee1, payee2, payee3} = await getNamedAccounts();
    const chainId = await getChainId();
    let linkToken;
    let linkTokenAddress;
    let VRFCoordinatorMock;
    let vrfCoordinatorAddress;
    let additionalMessage= "";
    let keyHash;
    let fee;
    let rewardedAddresses;
    let paymentsTo;
    let communityWallet;

    if(chainId == 31337) {
        communityWallet = user3;
        rewardedAddresses = [user2]
        paymentsTo = [
            payee1,
            payee2,
            payee3,
        ];

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


    const minter = await deploy("Minter", {
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

    const game = await deploy("Game", {
        from: deployer,
        args: [
            minter.address,
            communityWallet,
            ethers.utils.parseUnits("1", 18),
            vrfCoordinatorAddress,
            linkTokenAddress,
            keyHash,
            ethers.utils.parseUnits(fee, 18),
            1000,
        ],
        log: true,
    });



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