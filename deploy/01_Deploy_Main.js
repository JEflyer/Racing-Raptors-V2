const {config} = require("../config/chainlink.config.js");

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

    if(chainId == 31337) {
        rewardedAddresses = [user2]
        paymentsTo = [
            payee1,
            payee2,
            payee3,
        ];

        log(payee1);
        log(payee2);
        log(payee3);

        linkToken = await get("LinkToken");
        VRFCoordinatorMock = await get("VRFCoordinatorMock");
        linkTokenAddress = linkToken.address;
        vrfCoordinatorAddress = VRFCoordinatorMock.address;

        log(linkTokenAddress);
        log(vrfCoordinatorAddress);
        
        additionalMessage = " --linkAddress " + linkTokenAddress + " --fundamount " + config[chainId].fundAmount;
    }else {
        linkTokenAddress = config[chainId].linkToken;
        vrfCoordinatorAddress = config[chainId].vrfCoordinator;
    }

    keyHash = config[chainId].linkToken;
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

    log("Run the following command to fund contract with LINK:");
    log(
        "npx hardhat fund-link --contract " +
        minter.address +
        " --network " +
        config[chainId].name +
        additionalMessage
    );
    log("-------------------------------------------------------");
};