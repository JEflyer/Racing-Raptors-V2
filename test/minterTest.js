const {expect} = require("chai");
const {ethers, waffle} = require("hardhat");

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

let owner,  addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9;
let pay1, pay2, pay3;
let provider;

let newStats = {
    speed: 2,
    strength:1,
    agressiveness:1,
    fightsWon:0,
    fightsLost:0,
    quickPlayRacesWon:1,
    quickPlayRacesLost:2,
    compRacesWon:2,
    compRacesLost:1,
    deathRacesWon:0,
    deathRacesLost:0,
    deathRacesSurvived:0,
    deathRaceFightsWon:0,
    totalRacesTop3Finish:0,
    cooldownTime:0,
    foundingRaptor:true,
}


// describe("Testing Minter Contract", () => {
//     beforeEach(async () => {
//         provider = ethers.provider;
//         [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9] = await ethers.getSigners();
    
//         const Minter = await ethers.getContractFactory("Minter");
//         const Game = await ethers.getContractFactory("Game");
    
//         //for minter constructor
//         const rewardedAddresses = [addr7.address, addr8.address, addr9.address];
//         const paymentsTo = [owner.address, addr1.address, addr2.address];
        
//         minter = await Minter.deploy(
//             baseUri,
//             CID,
//             NotRevealed,
//             extension,
//             totalLimit,
//             soldOutMessage,
//             rewardedAddresses,
//             paymentsTo
//         );
        
        
//         //for game constructor
//         const communityWallet = addr6.address;
//         const minterAddress = minter.address;
        
    
//         game = await Game.deploy(
//             minterAddress,
//             communityWallet,
//             QPFee,
//             CompFee,
//             DRFee
//         );
//     })
    //--------------------------COMPLETELY-WORKING-------------------------------//
    // it("Should allow the setting of the game contract", async() => {
    //     await minter.connect(owner).updateGameAddress(game.address);
    //     expect(await minter.gameAddress()).to.be.equal(game.address);
    // })
    
    // it("Should not allow the setting of the game contract from a different wallet", async() => {
    //     await expect(minter.connect(addr1).updateGameAddress(game.address)).to.be.revertedWith("Only A");
    // })
    
    // it("Should update a paymentTo address", async() => {
    //     await minter.connect(owner).updatePaymentTo(addr1.address, 2);
    //     expect(await minter.paymentsTo(2)).to.be.equal(addr1.address);
    // })
    
    // it("Should get the correct price for the first 10", async() => {
    //     expect(await minter.getPrice(10)).to.be.equal(ethers.utils.parseEther("20"));    
    // })
    
    // it("Should get the correct price for 10 mints, 5 before price increase 5 after price increase", async() => { // 5 mints are already minted as placeholder rewards for V1 holders
    //     for (let i = 0; i < 99; i++){
    //         await minter.connect(owner).mint(10);
    //     }
    //     expect(await minter.getPrice(10)).to.be.equal(ethers.utils.parseEther("30"));
    // })
    
    // it("Should return the correct total minted amount", async() => {
    //     expect(await minter.getTotalMinted()).to.be.equal(5);
    // })
    
    // it("Should allow the admin to unreveal the NFT images", async() => {
    //     await minter.connect(owner).reveal();
    //     expect(await minter.revealed()).to.be.true;
    // })
    
    // it("Should not allow a different wallet to unreveal the NFT images", async() => {
    //     expect( minter.connect(addr1).reveal()).to.be.revertedWith("Only A");
    // })
     
    // it("Should allow the admin to flip sale state", async() => {
    //     await minter.connect(owner).flipSaleState();
    //     expect(await minter.active()).to.be.false;  
    // })
      
    // it("Should not allow a different wallet to flip sale state", async() => {
    //     expect(minter.connect(addr1).flipSaleState()).to.be.revertedWith("Only A");
    // })
    
    // it("Should allow the admin to change the admin address", async() => {
    //     await minter.connect(owner).setAdmin(addr1.address);
    //     expect(await minter.admin()).to.be.equal(addr1.address);
    // })
     
    // it("Should not allow a different wallet to change the admin", async() => {
    //     expect(minter.connect(addr1).setAdmin(addr1.address)).to.be.revertedWith("Only A");
    // })
    
    // it("Should split funds correctly if funds are sent to the contract", async() => {
    //     let startingBalance = ethers.utils.formatEther(await provider.getBalance(owner.address));
    //     console.log("owner ",startingBalance);

    //     let pay1StartingBalance = ethers.utils.formatEther(await provider.getBalance(addr1.address));
    //     console.log("addr1 ",pay1StartingBalance);

    //     let pay2StartingBalance = ethers.utils.formatEther(await provider.getBalance(addr2.address));
    //     console.log("addr2 ",pay2StartingBalance);


    //     await minter.connect(addr5).mint(1,{value: ethers.utils.parseEther("2")});
    //     console.log("mint: 2 eth sent");
        
    //     let pay2EndingBalance = ethers.utils.formatEther(await provider.getBalance(addr2.address));
    //     console.log("addr2 ",pay2EndingBalance);
        

    //     let pay1EndingBalance = ethers.utils.formatEther(await provider.getBalance(addr1.address));
    //     console.log("addr1 ",pay1EndingBalance);
        
    //     let endingBalance = ethers.utils.formatEther(await provider.getBalance(owner.address));
    //     console.log("owner ",endingBalance);
    //     expect(endingBalance-startingBalance).to.be.equal(0.5);
    // })
    // it("Should set stats correctly on mint", async() => {//not 100% sure how to test this one but the stats log correctly
    //     await minter.connect(addr1).mint(1,{value: ethers.utils.parseEther("2")});
    //     console.log(await minter.connect(addr1).getStats(6));
    // })
    
    // it("Should return the correct tokens owned by a wallet", async() => {
    //     await minter.connect(addr1).mint(1, {value: ethers.utils.parseEther("2")});
    //     let tokenIDs = await minter.connect(addr1).walletOfOwner(addr1.address);
    //     expect(tokenIDs[0]).to.be.equal(6);
    // })
    
    // it("Should not allow the admin to update stats", async() => {
        // await minter.connect(owner).mint(1);
        // expect(minter.connect(owner).updateStats(newStats, 6)).to.be.revertedWith("only GC");
    // })
    
    // it("Should not allow a different wallet to update the stats", async() => {
    //     await minter.connect(addr1).mint(1, {value: ethers.utils.parseEther("2")});
    //     expect(minter.connect(addr1).updateStats(newStats, 6)).to.be.revertedWith("only GC");
    // })
    
    // it("Should reward V1 holders correctly", async() => {
    //     let tokenId = await minter.connect(addr7).walletOfOwner(addr7.address);
    //     expect(tokenId[0]).to.be.equal(1)
    // })
    
    // it("Should give the correct price from getPrice", async() => {
    //     let price = await minter.getPrice(2);
    //     expect(price).to.be.equal(ethers.utils.parseEther("4"));
    // })
    //--------------------------COMPLETELY-WORKING-------------------------------//
// })


// describe("Testing Game Contract", () => {
//     beforeEach(async()=> {
//         minter.updateGameAddress.connect(owner)(game.address);
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



// describe("Testing Minter/Game Contract Interaction", () => {
//     beforeEach(async()=> {
//         minter.updateGameAddress.connect(owner)(game.address);
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