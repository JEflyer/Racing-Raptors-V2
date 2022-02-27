module.exports = async ({ getNamedAccounts, deployments, getChainId}) => {
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    const chainId = await getChainId();

    if(chainId == 31337) {
        log("Local Network Detected, Deploying external contracts");
        const linkToken = await deploy("LinkToken", {from: deployer, log: true});
        const vrf = await deploy("VRFCoordinatorMock", {
            from: deployer,
            log: true,
            args: [linkToken.address],
        });
        await linkToken.wait;
        await vrf.wait;
    }
};

module.exports.tags = ["all", "mocks", "main"];