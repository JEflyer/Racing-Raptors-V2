const {expect} = require("chai");
const {ethers, getChainId, deployments} = require("hardhat");
const {config, autoFundCheck} = require("../config/chainlink.config.js");

//minter constructor vars
const baseUri = "This is the uri/";
const CID = "This is the CID/";
const NotRevealed = "This is the entire API link to the unrevealed image";
const extension = ".JSON";
const totalLimit = 10000;
const soldOutMessage = "So this is what the moon looks like";

// game constructor vars
const QPFee = 5;
const CompFee = 25;
const DRFee = 100;

let minter;
let game;

let deployer, user2, user3, payee1, payee2, payee3, addr6, addr7, addr8, addr9;
let provider;

let _vrfCoordinator;
let _linkToken;
let _keyHash;
let _OracleFee;

let linkToken;
let LinkToken;
let chainId;
let Game;
let Minter;


describe("Contract Testing", () => {
    beforeEach(async () => {
        provider = ethers.provider;
        [deployer, user2, user3, payee1, payee2, payee3, addr6, addr7, addr8, addr9] = await ethers.getSigners();
        
        chainId = await getChainId();
        await deployments.fixture(["main"]);
        LinkToken = await deployments.get("LinkToken");
        linkToken = await ethers.getContractAt("LinkToken", LinkToken.address);

        Minter = await deployments.get("Minter");
        minter = await ethers.getContractAt("Minter", Minter.address);

        Game = await deployments.get("Game");
        game = await ethers.getContractAt("Game", Game.address);
    })

    // describe("Testing Minter Contract", () => {
        
        //--------------------------COMPLETELY-WORKING-------------------------------//
        // it("Should allow the setting of the game contract", async() => {
        //     await minter.connect(deployer).updateGameAddress(Game.address);
        //     expect(await minter.gameAddress()).to.be.equal(Game.address);
        // })
        
        // it("Should not allow the setting of the game contract from a different wallet", async() => {
        //     await expect(minter.connect(user2).updateGameAddress(game.address)).to.be.revertedWith("Err: A");
        // })
        
        // it("Should allow admin to update a paymentTo address", async() => {
        //     await minter.connect(deployer).updatePaymentTo(user2.address, 2);
        //     expect(await minter.paymentsTo(2)).to.be.equal(user2.address);
        // })

        // it("Should not allow a different wallet to update a paymentTo address", async() => {
        //     expect(minter.connect(user2).updatePaymentTo(user2.address, 2)).to.be.revertedWith("Err: A");
        // })
        
        // it("Should get the correct price for the first 10", async() => {
        //     expect(await minter.getPrice(10)).to.be.equal(ethers.utils.parseEther("20"));    
        // })
        
        // it("Should get the correct price for 10 mints, 5 before price increase 5 after price increase", async() => { // 3 mints are already minted as placeholder rewards for V1 holders
        //     for (let i = 0; i < 99; i++){
        //         await minter.connect(deployer).mint(10);
        //     }
        //     await minter.connect(deployer).mint(2);
        //     expect(await minter.getPrice(10)).to.be.equal(ethers.utils.parseEther("30"));
        // })
        
        // it("Should return the correct total minted amount", async() => {
        //     expect(await minter.totalMintSupply()).to.be.equal(3);
        // })
        
        // it("Should allow the admin to unreveal the NFT images", async() => {
        //     await minter.connect(deployer).reveal();
        //     expect(await minter.revealed()).to.be.true;
        // })
        
        // it("Should not allow a different wallet to unreveal the NFT images", async() => {
        //     expect( minter.connect(user2).reveal()).to.be.revertedWith("Err: A");
        // })
        
        // it("Should allow the admin to flip sale state", async() => {
        //     await minter.connect(deployer).flipSaleState();
        //     expect(await minter.active()).to.be.false;  
        // })
        
        // it("Should not allow a different wallet to flip sale state", async() => {
        //     expect(minter.connect(user2).flipSaleState()).to.be.revertedWith("Err: A");
        // })
        
        // it("Should allow the admin to change the admin address", async() => {
        //     await minter.connect(deployer).setAdmin(user2.address);
        //     expect(await minter.admin()).to.be.equal(user2.address);
        // })
        
        // it("Should not allow a different wallet to change the admin", async() => {
        //     expect(minter.connect(user2).setAdmin(user2.address)).to.be.revertedWith("Err: A");
        // })
        
        // it("Should split funds correctly if funds are sent to the contract", async() => {
        //     let payee1StartingBalance = ethers.utils.formatEther(await provider.getBalance(payee1.address));
        //     console.log("payee1 ",payee1StartingBalance);

        //     let payee2StartingBalance = ethers.utils.formatEther(await provider.getBalance(payee2.address));
        //     console.log("payee2 ",payee2StartingBalance);

        //     let payee3StartingBalance = ethers.utils.formatEther(await provider.getBalance(payee3.address));
        //     console.log("payee3 ",payee3StartingBalance);


        //     await minter.connect(user3).mint(1,{value: ethers.utils.parseEther("2")});
        //     console.log("mint: 2 eth sent");
            
        //     let payee1EndingBalance = ethers.utils.formatEther(await provider.getBalance(payee1.address));
        //     console.log("payee1 ",payee1EndingBalance);
            

        //     let payee2EndingBalance = ethers.utils.formatEther(await provider.getBalance(payee2.address));
        //     console.log("payee2 ",payee2EndingBalance);
            
        //     let payee3EndingBalance = ethers.utils.formatEther(await provider.getBalance(payee3.address));
        //     console.log("payee3 ",payee3EndingBalance);
        //     expect(payee1EndingBalance-payee1StartingBalance).to.be.equal(0.5);
        // })

        // it("Should set stats correctly on mint", async() => {//not 100% sure how to test this one but the stats log correctly
        //     await minter.connect(user2).mint(1,{value: ethers.utils.parseEther("2")});
        //     console.log(await minter.connect(user2).raptorStats(4));
        // })
        
        // it("Should return the correct tokens owned by a wallet", async() => {
        //     await minter.connect(user3).mint(1, {value: ethers.utils.parseEther("2")});
        //     let tokenIDs = await minter.connect(user3).walletOfOwner(user3.address);
        //     console.log(tokenIDs);
        //     expect(tokenIDs[0]).to.be.equal(4);
        // })    
        
        // it("Should reward V1 holders correctly", async() => {
        //     let tokenIDs = await minter.connect(user2).walletOfOwner(user2.address);
        //     expect(tokenIDs[0]).to.be.equal(1)
        // })
        
        // it("Should give the correct price from getPrice", async() => {
        //     let price = await minter.getPrice(2);
        //     expect(price).to.be.equal(ethers.utils.parseEther("4"));
        // })

        // it("Should not allow a wallet to upgrade speed", async() => {
        //     expect(minter.connect(deployer).upgradeSpeed(1, 2)).to.be.revertedWith("Err: GC");
        // })
        
        // it("Should not allow a wallet to upgrade strength", async() => {
        //     expect(minter.connect(deployer).upgradeStrength(1, 2)).to.be.revertedWith("Err: GC");
        // })
        
        // it("Should not allow a wallet to upgrade fights won", async() => {
        //     expect(minter.connect(deployer).upgradeFightsWon(1)).to.be.revertedWith("Err: GC");
        // })
        
        // it("Should not allow a wallet to upgrade QP Wins", async() => {
        //     expect(minter.connect(deployer).upgradeQPWins(1)).to.be.revertedWith("Err: GC");
        // })

        // it("Should not allow a wallet to upgrade Comp Wins", async() => {
        //     expect(minter.connect(deployer).upgradeCompWins(1)).to.be.revertedWith("Err: GC");
        // })

        // it("Should not allow a wallet to upgrade DR Wins", async() => {
        //     expect(minter.connect(deployer).upgradeDRWins(1)).to.be.revertedWith("Err: GC");
        // })

        // it("Should not allow a wallet to upgrade top 3 finishes", async() => {
        //     expect(minter.connect(deployer).upgradeTop3Finishes(1)).to.be.revertedWith("Err: GC");
        // })

        // it("Should not allow a wallet to increase cooldown", async() => {
        //     expect(minter.connect(deployer).increaseCooldownTime(1, 145126425)).to.be.revertedWith("Err: GC");
        // })
        //-------------------------------completely working------------------------------------------------//

        // //unsure if this will work as oracle calls a different function - max mint limit changed to 1k for this test
        // it("Should emit event for porsche winner ", async() => { // 3 mints are already minted as placeholder rewards for V1 holders
        //     for (let i = 0; i < 19; i++){
        //         await minter.connect(addr9).mint(10, {value: ethers.utils.parseEther("20")});
        //         await minter.connect(addr8).mint(10, {value: ethers.utils.parseEther("20")});
        //         await minter.connect(addr7).mint(10, {value: ethers.utils.parseEther("20")});
        //         await minter.connect(user2).mint(10, {value: ethers.utils.parseEther("20")});
        //         await minter.connect(user3).mint(10, {value: ethers.utils.parseEther("20")});
        //     }
        //     await minter.connect(addr9).mint(10, {value: ethers.utils.parseEther("20")});
        //     await minter.connect(addr8).mint(10, {value: ethers.utils.parseEther("20")});
        //     await minter.connect(addr7).mint(10, {value: ethers.utils.parseEther("20")});
        //     await minter.connect(user2).mint(10, {value: ethers.utils.parseEther("20")});
        //     await minter.connect(user3).mint(6, {value: ethers.utils.parseEther("12")});

        //     const networkName = config[chainId].name;
        //     const additionalMessage = " --linkaddress " + linkToken.address;

            
            // await hre.run("fund-link", {
            //     contract: minter.address,
            //     linkaddress: linkToken.address,
            // });
            

        //     await minter.connect(deployer).mint(1);

        //     //can't figure out how to test an oracle response in a local hardhat environment

        //     //tried minter.queryFilter("PorscheWinner"); - didn't work
        // })
        
        
    // })


    describe("Testing Game Contract", () => {
        // beforeEach(async()=> {

        //     minter.connect(user2).mint(1, {value: ethers.utils.parseEther("2")});
        //     minter.connect(deployer).mint(1);
        //     minter.connect(user3).mint(1, {value: ethers.utils.parseEther("2")});
        //     minter.connect(payee1).mint(1, {value: ethers.utils.parseEther("2")});
        //     minter.connect(payee2).mint(1, {value: ethers.utils.parseEther("2")});
        //     minter.connect(payee3).mint(1, {value: ethers.utils.parseEther("2")});
        //     minter.connect(addr9).mint(1, {value: ethers.utils.parseEther("2")});
        //     minter.connect(addr8).mint(1, {value: ethers.utils.parseEther("2")});
        //     minter.connect(addr7).mint(1, {value: ethers.utils.parseEther("2")});

        //     await hre.run("fund-link", {
        //         contract: game.address,
        //         linkaddress: linkToken.address,
        //     });
            
        // })
        
        // it("Should allow the admin to set a race", async() => {
        //     await game.connect(deployer).raceSelect(1);
        //     expect(await game.currentRace()).to.be.equal(1);
        // })
        // it("Should allow a user to enter their raptor into the race - QP", async() => {
        //     await game.connect(deployer).raceSelect(1);
        //     let raptors = await minter.connect(user2).walletOfOwner(user2.address);
        //     await game.connect(user2).enterRaptorIntoQuickPlay(raptors[0], {value: ethers.utils.parseEther("1")});
        //     let currentRaptors = await game.getCurrentQueue();
        //     console.log(raptors);
        //     console.log(currentRaptors);
        //     expect(currentRaptors[0]).to.be.equal(raptors[0]);
        // })
        it("Should start a QP race", async() => {
            await game.connect(deployer).raceSelect(1);

            let user2Raptors = await minter.connect(user2).walletOfOwner(user2.address);
            await game.connect(user2).enterRaptorIntoQuickPlay(user2Raptors[0], {value: ethers.utils.parseEther("1")});

            let user3Raptors = await minter.connect(user3).walletOfOwner(user3.address);
            await game.connect(user3).enterRaptorIntoQuickPlay(user3Raptors[0], {value: ethers.utils.parseEther("1")});

            let deployerRaptors = await minter.connect(deployer).walletOfOwner(deployer.address);
            await game.connect(deployer).enterRaptorIntoQuickPlay(deployerRaptors[0], {value: ethers.utils.parseEther("1")});

            let payee1Raptors = await minter.connect(payee1).walletOfOwner(payee1.address);
            await game.connect(payee1).enterRaptorIntoQuickPlay(payee1Raptors[0], {value: ethers.utils.parseEther("1")});

            let payee2Raptors = await minter.connect(payee2).walletOfOwner(payee2.address);
            await game.connect(payee2).enterRaptorIntoQuickPlay(payee2Raptors[0], {value: ethers.utils.parseEther("1")});

            let payee3Raptors = await minter.connect(payee3).walletOfOwner(payee3.address);
            await game.connect(payee3).enterRaptorIntoQuickPlay(payee3Raptors[0], {value: ethers.utils.parseEther("1")});

            let addr7Raptors = await minter.connect(addr7).walletOfOwner(addr7.address);
            await game.connect(addr7).enterRaptorIntoQuickPlay(addr7Raptors[0], {value: ethers.utils.parseEther("1")});

            let addr8Raptors = await minter.connect(addr8).walletOfOwner(addr8.address);
            expect(await game.connect(addr8).enterRaptorIntoQuickPlay(addr8Raptors[0], {value: ethers.utils.parseEther("1")})).to.emit(game, "QPRandomRequested");
        })
        // it("Should start a Comp race", async() => {
        //     await game.connect(deployer).raceSelect(2);

        //     let user2Raptors = await minter.connect(user2).walletOfOwner(user2.address);
        //     await game.connect(user2).enterRaptorIntoComp(user2Raptors[0], {value: ethers.utils.parseEther("5")});

        //     let user3Raptors = await minter.connect(user3).walletOfOwner(user3.address);
        //     await game.connect(user3).enterRaptorIntoComp(user3Raptors[0], {value: ethers.utils.parseEther("5")});

        //     let deployerRaptors = await minter.connect(deployer).walletOfOwner(deployer.address);
        //     await game.connect(deployer).enterRaptorIntoComp(deployerRaptors[0], {value: ethers.utils.parseEther("5")});

        //     let payee1Raptors = await minter.connect(payee1).walletOfOwner(payee1.address);
        //     await game.connect(payee1).enterRaptorIntoComp(payee1Raptors[0], {value: ethers.utils.parseEther("5")});

        //     let payee2Raptors = await minter.connect(payee2).walletOfOwner(payee2.address);
        //     await game.connect(payee2).enterRaptorIntoComp(payee2Raptors[0], {value: ethers.utils.parseEther("5")});

        //     let payee3Raptors = await minter.connect(payee3).walletOfOwner(payee3.address);
        //     await game.connect(payee3).enterRaptorIntoComp(payee3Raptors[0], {value: ethers.utils.parseEther("5")});

        //     let addr7Raptors = await minter.connect(addr7).walletOfOwner(addr7.address);
        //     await game.connect(addr7).enterRaptorIntoComp(addr7Raptors[0], {value: ethers.utils.parseEther("5")});

        //     let addr8Raptors = await minter.connect(addr8).walletOfOwner(addr8.address);
        //     expect(await game.connect(addr8).enterRaptorIntoComp(addr8Raptors[0], {value: ethers.utils.parseEther("5")})).to.emit(game, "CompRandomRequested");
        // })
        // it("Should start a DR race", async() => {
        //     await game.connect(deployer).raceSelect(3);

        //     let user2Raptors = await minter.connect(user2).walletOfOwner(user2.address);
        //     await game.connect(user2).enterRaptorIntoDR(user2Raptors[0], {value: ethers.utils.parseEther("25")});

        //     let user3Raptors = await minter.connect(user3).walletOfOwner(user3.address);
        //     await game.connect(user3).enterRaptorIntoDR(user3Raptors[0], {value: ethers.utils.parseEther("25")});

        //     let deployerRaptors = await minter.connect(deployer).walletOfOwner(deployer.address);
        //     await game.connect(deployer).enterRaptorIntoDR(deployerRaptors[0], {value: ethers.utils.parseEther("25")});

        //     let payee1Raptors = await minter.connect(payee1).walletOfOwner(payee1.address);
        //     await game.connect(payee1).enterRaptorIntoDR(payee1Raptors[0], {value: ethers.utils.parseEther("25")});

        //     let payee2Raptors = await minter.connect(payee2).walletOfOwner(payee2.address);
        //     await game.connect(payee2).enterRaptorIntoDR(payee2Raptors[0], {value: ethers.utils.parseEther("25")});

        //     let payee3Raptors = await minter.connect(payee3).walletOfOwner(payee3.address);
        //     await game.connect(payee3).enterRaptorIntoDR(payee3Raptors[0], {value: ethers.utils.parseEther("25")});

        //     let addr7Raptors = await minter.connect(addr7).walletOfOwner(addr7.address);
        //     await game.connect(addr7).enterRaptorIntoDR(addr7Raptors[0], {value: ethers.utils.parseEther("25")});

        //     let addr8Raptors = await minter.connect(addr8).walletOfOwner(addr8.address);
        //     expect(await game.connect(addr8).enterRaptorIntoDR(addr8Raptors[0], {value: ethers.utils.parseEther("25")})).to.emit(game, "DRRandomRequested");    
        // })
        // it("Should payout correctly on a QP race", async() => {

        //     let communityBal = ethers.utils.formatEther(await provider.getBalance(user3.address));
        //     await game.connect(deployer).raceSelect(1);

        //     let user2Raptors = await minter.connect(user2).walletOfOwner(user2.address);
        //     await game.connect(user2).enterRaptorIntoQuickPlay(user2Raptors[0], {value: ethers.utils.parseEther("1")});

        //     let addr9Raptors = await minter.connect(addr9).walletOfOwner(addr9.address);
        //     await game.connect(addr9).enterRaptorIntoQuickPlay(addr9Raptors[0], {value: ethers.utils.parseEther("1")});

        //     let deployerRaptors = await minter.connect(deployer).walletOfOwner(deployer.address);
        //     await game.connect(deployer).enterRaptorIntoQuickPlay(deployerRaptors[0], {value: ethers.utils.parseEther("1")});

        //     let payee1Raptors = await minter.connect(payee1).walletOfOwner(payee1.address);
        //     await game.connect(payee1).enterRaptorIntoQuickPlay(payee1Raptors[0], {value: ethers.utils.parseEther("1")});

        //     let payee2Raptors = await minter.connect(payee2).walletOfOwner(payee2.address);
        //     await game.connect(payee2).enterRaptorIntoQuickPlay(payee2Raptors[0], {value: ethers.utils.parseEther("1")});

        //     let payee3Raptors = await minter.connect(payee3).walletOfOwner(payee3.address);
        //     await game.connect(payee3).enterRaptorIntoQuickPlay(payee3Raptors[0], {value: ethers.utils.parseEther("1")});

        //     let addr7Raptors = await minter.connect(addr7).walletOfOwner(addr7.address);
        //     await game.connect(addr7).enterRaptorIntoQuickPlay(addr7Raptors[0], {value: ethers.utils.parseEther("1")});

        //     let addr8Raptors = await minter.connect(addr8).walletOfOwner(addr8.address);
        //     await game.connect(addr8).enterRaptorIntoQuickPlay(addr8Raptors[0], {value: ethers.utils.parseEther("1")});

            
        //     await ethers.provider.send("evm_increaseTime", [3600 * 24 * 2]);
            
        //     let endingCommunityBal = ethers.utils.formatEther(await provider.getBalance(user3.address));
        //     let diff = endingCommunityBal - communityBal;
        //     expect(diff).to.be.equal(8/20)
        // })
        // it("Should payout correctly on a Comp race", async() => {

        // })
        // it("Should payout correctly on a DR race", async() => {

        // })
        // it("Should return the current race queue", async() => {

        // })
        // it("Should give the correct current race", async() => {
            
        // })
        // it("Should not allow a wallet other than the admin to start a race", async() => {
            
        // })
        // it("Should not allow a ERC721 token to be sent to the contract", async() => {
            
        // })
        // it("Should emit an event when a QP race starts", async() => {
            
        // })
        // it("Should emit an event when a Comp race starts", async() => {
            
        // })
        // it("Should emit an event when a DR race starts", async() => {
            
        // })
        // it("Should generate psuedorandom numbers from the random number provided by ", async() => {
            
        // })
        // it("Should ", async() => {
            
        // })
    })



    // describe("Testing Minter/Game Contract Interaction", () => {
    //     beforeEach(async()=> {
    //         minter.updateGameAddress.connect(deployer)(game.address);
    //     })
    //     it("Should ", async() => {

    //     })
    //     it("Should ", async() => {
            
    //     })
    //     it("Should ", async() => {
            
    //     })
    //     it("Should ", async() => {
            
    //     })
    //     it("Should ", async() => {
            
    //     })
    //     it("Should ", async() => {
            
    //     })
    // })

});