const {expect} = require("chai");
const {ethers} = require("hardhat");

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



describe("Testing Minter Contract", () => {
    beforeEach(async () => {

        [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9] = await ethers.getSigners();
        [pay1, pay2, pay3] = await ethers.getSigners();
    
        const Minter = await ethers.getContractFactory("Minter");
        const Game = await ethers.getContractFactory("Game");
    
        //for minter constructor
        const rewardedAddresses = [addr7.address, addr8.address, addr9.address];
        const paymentsTo = [owner.address, pay1.address, pay2.address, pay3.address];
        
        minter = await Minter.deploy(
            baseUri,
            CID,
            NotRevealed,
            extension,
            totalLimit,
            soldOutMessage,
            rewardedAddresses,
            paymentsTo
        );
        
        
        //for game constructor
        const communityWallet = addr6.address;
        const minterAddress = minter.address;
        
    
        game = await Game.deploy(
            minterAddress,
            communityWallet,
            QPFee,
            CompFee,
            DRFee
        );
    })
    //--------------------------WORKING-------------------------------//
    it("Should allow the setting of the game contract", async() => {
        await minter.connect(owner).updateGameAddress(game.address);
        expect(await minter.gameAddress()).to.be.equal(game.address);
    })
    
    it("Should not allow the setting of the game contract from a different wallet", async() => {
        await expect(minter.connect(addr1).updateGameAddress(game.address)).to.be.revertedWith("Only A");
    })
    
    it("Should update a paymentTo address", async() => {
        await minter.connect(owner).updatePaymentTo(addr1.address, 2);
        expect(await minter.paymentsTo(2)).to.be.equal(addr1.address);
    })
    
    it("Should get the correct price for the first 10", async() => {
        expect(await minter.getPrice(10)).to.be.equal(ethers.utils.parseEther("20"));    
    })
    
    it("Should get the correct price for 10 mints, 5 before price increase 5 after price increase", async() => { // 5 mints are already minted as placeholder rewards for V1 holders
        for (let i = 0; i < 99; i++){
            await minter.connect(owner).mint(10);
        }
        expect(await minter.getPrice(10)).to.be.equal(ethers.utils.parseEther("30"));
    })
    
    it("Should return the correct total minted amount", async() => {
        expect(await minter.getTotalMinted()).to.be.equal(5);
    })
    
    it("Should allow the admin to unreveal the NFT images", async() => {
        await minter.connect(owner).reveal();
        expect(await minter.revealed()).to.be.true;
    })
    
    it("Should not allow a different wallet to unreveal the NFT images", async() => {
        expect( minter.connect(addr1).reveal()).to.be.revertedWith("Only A");
    })
     
    it("Should allow the admin to flip sale state", async() => {
        await minter.connect(owner).flipSaleState();
        expect(await minter.active()).to.be.false;  
    })
      
    it("Should not allow a different wallet to flip sale state", async() => {
        expect(minter.connect(addr1).flipSaleState()).to.be.revertedWith("Only A");
    })
    
    it("Should allow the admin to change the admin address", async() => {
        await minter.connect(owner).setAdmin(addr1.address);
        expect(await minter.admin()).to.be.equal(addr1.address);
    })
     
    it("Should not allow a different wallet to change the admin", async() => {
        expect(minter.connect(addr1).setAdmin(addr1.address)).to.be.revertedWith("Only A");
    })
    //--------------------------WORKING-------------------------------//
    // it("Should split funds correctly if funds are sent to the contract", async() => {
        
    // })
    // it("Should split the funds correctly if someone mints", async() => {
        
    // })
    // it("Should mint correctly", async() => {
        
    // })
    // it("Should set stats correctly on mint", async() => {
        
    // })
    // it("Should return the correct tokens owned by a wallet", async() => {
        
    // })
    // it("Should not allow the admin to update stats", async() => {
        
    // })
    // it("Should not allow a different wallet to update the stats", async() => {
        
    // })
    // it("Should reward V1 holders correctly", async() => {
        
    // })
    // it("Should update the price correctly", async() => {
        
    // })
    // it("Should give the correct price from getPrice when crossing threshold", async() => {
        
    // })
})


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