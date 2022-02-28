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

let newStats = {
    speed: 2,
    strength:1,
    fightsWon:0,
    quickPlayRacesWon:1,
    compRacesWon:2,
    deathRacesWon:0,
    totalRacesTop3Finish:0,
    cooldownTime:0
}

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

    describe("Testing Minter Contract", () => {
        
        //--------------------------COMPLETELY-WORKING-------------------------------//
        it("Should allow the setting of the game contract", async() => {
            await minter.connect(deployer).updateGameAddress(Game.address);
            expect(await minter.gameAddress()).to.be.equal(Game.address);
        })
        
        it("Should not allow the setting of the game contract from a different wallet", async() => {
            await expect(minter.connect(user2).updateGameAddress(game.address)).to.be.revertedWith("Err: A");
        })
        
        it("Should update a paymentTo address", async() => {
            await minter.connect(deployer).updatePaymentTo(user2.address, 2);
            expect(await minter.paymentsTo(2)).to.be.equal(user2.address);
        })
        
        it("Should get the correct price for the first 10", async() => {
            expect(await minter.getPrice(10)).to.be.equal(ethers.utils.parseEther("20"));    
        })
        
        it("Should get the correct price for 10 mints, 5 before price increase 5 after price increase", async() => { // 5 mints are already minted as placeholder rewards for V1 holders
            for (let i = 0; i < 99; i++){
                await minter.connect(deployer).mint(10);
            }
            await minter.connect(deployer).mint(2);
            expect(await minter.getPrice(10)).to.be.equal(ethers.utils.parseEther("30"));
        })
        
        it("Should return the correct total minted amount", async() => {
            expect(await minter.totalMintSupply()).to.be.equal(3);
        })
        
        it("Should allow the admin to unreveal the NFT images", async() => {
            await minter.connect(deployer).reveal();
            expect(await minter.revealed()).to.be.true;
        })
        
        it("Should not allow a different wallet to unreveal the NFT images", async() => {
            expect( minter.connect(user2).reveal()).to.be.revertedWith("Err: A");
        })
        
        it("Should allow the admin to flip sale state", async() => {
            await minter.connect(deployer).flipSaleState();
            expect(await minter.active()).to.be.false;  
        })
        
        it("Should not allow a different wallet to flip sale state", async() => {
            expect(minter.connect(user2).flipSaleState()).to.be.revertedWith("Err: A");
        })
        
        it("Should allow the admin to change the admin address", async() => {
            await minter.connect(deployer).setAdmin(user2.address);
            expect(await minter.admin()).to.be.equal(user2.address);
        })
        
        it("Should not allow a different wallet to change the admin", async() => {
            expect(minter.connect(user2).setAdmin(user2.address)).to.be.revertedWith("Err: A");
        })
        
        it("Should split funds correctly if funds are sent to the contract", async() => {
            let startingBalance = ethers.utils.formatEther(await provider.getBalance(deployer.address));
            console.log("deployer ",startingBalance);

            let pay1StartingBalance = ethers.utils.formatEther(await provider.getBalance(user2.address));
            console.log("user2 ",pay1StartingBalance);

            let pay2StartingBalance = ethers.utils.formatEther(await provider.getBalance(user3.address));
            console.log("user3 ",pay2StartingBalance);


            await minter.connect(addr3).mint(1,{value: ethers.utils.parseEther("2")});
            console.log("mint: 2 eth sent");
            
            let pay2EndingBalance = ethers.utils.formatEther(await provider.getBalance(user3.address));
            console.log("user3 ",pay2EndingBalance);
            

            let pay1EndingBalance = ethers.utils.formatEther(await provider.getBalance(user2.address));
            console.log("user2 ",pay1EndingBalance);
            
            let endingBalance = ethers.utils.formatEther(await provider.getBalance(deployer.address));
            console.log("deployer ",endingBalance);
            expect(endingBalance-startingBalance).to.be.equal(0.5);
        })
        it("Should set stats correctly on mint", async() => {//not 100% sure how to test this one but the stats log correctly
            await minter.connect(user2).mint(1,{value: ethers.utils.parseEther("2")});
            console.log(await minter.connect(user2).getStats(6));
        })
        
        it("Should return the correct tokens owned by a wallet", async() => {
            await minter.connect(user2).mint(1, {value: ethers.utils.parseEther("2")});
            let tokenIDs = await minter.connect(user2).walletOfOwner(user2.address);
            expect(tokenIDs[0]).to.be.equal(6);
        })
        
        it("Should not allow the admin to update stats", async() => {
            await minter.connect(deployer).mint(1);
            expect(minter.connect(deployer).updateStats(newStats, 6)).to.be.revertedWith("Err: GC");
        })
        
        it("Should not allow a different wallet to update the stats", async() => {
            await minter.connect(user2).mint(1, {value: ethers.utils.parseEther("2")});
            expect(minter.connect(user2).updateStats(newStats, 6)).to.be.revertedWith("Err: GC");
        })
        
        it("Should reward V1 holders correctly", async() => {
            let tokenId = await minter.connect(addr7).walletOfOwner(addr7.address);
            expect(tokenId[0]).to.be.equal(1)
        })
        
        it("Should give the correct price from getPrice", async() => {
            let price = await minter.getPrice(2);
            expect(price).to.be.equal(ethers.utils.parseEther("4"));
        })
        
    })


    // describe("Testing Game Contract", () => {
    //     beforeEach(async()=> {
    //         minter.updateGameAddress.connect(deployer)(game.address);
    //     })
    //     it("Should allow a user to enter their raptor into the race", async() => {

    //     })
    //     it("Should allow the admin to set a race", async() => {
            
    //     })
    //     it("Should complete a QP race", async() => {
            
    //     })
    //     it("Should complete a Comp race", async() => {
            
    //     })
    //     it("Should complete a DR race", async() => {
            
    //     })
    //     it("Should payout correctly on a QP race", async() => {
            
    //     })
    //     it("Should payout correctly on a Comp race", async() => {

    //     })
    //     it("Should payout correctly on a DR race", async() => {

    //     })
    //     it("Should return the current race queue", async() => {

    //     })
    //     it("Should give the correct current race", async() => {
            
    //     })
    //     it("Should not allow a wallet other than the admin to start a race", async() => {
            
    //     })
    //     it("Should not allow a ERC721 token to be sent to the contract", async() => {
            
    //     })
    //     it("Should emit an event when a QP race starts", async() => {
            
    //     })
    //     it("Should emit an event when a Comp race starts", async() => {
            
    //     })
    //     it("Should emit an event when a DR race starts", async() => {
            
    //     })
    //     it("Should generate psuedorandom numbers from the random number provided by ", async() => {
            
    //     })
    //     it("Should ", async() => {
            
    //     })
    // })



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