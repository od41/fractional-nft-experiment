/* eslint-disable @typescript-eslint/ban-ts-comment */
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Marketplace tests", function () {

  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();
    const listingPrice = ethers.parseEther("0.1");

    const NFTContract = await ethers.getContractFactory("TestAsset");
    const nftContract = await NFTContract.deploy();

    const ERC20TokenContract = await ethers.getContractFactory("TestCoins");
    const erc20TokenContract = await ERC20TokenContract.deploy();
    
    const MarketplaceContract = await ethers.getContractFactory("Marketplace");
    const marketplaceContract = await MarketplaceContract.deploy(nftContract.target, erc20TokenContract.target, listingPrice);

    const tokenId = 0;
    const initialShares = [{ tokenId, share: 5000 }];

    return {
        nftContract, erc20TokenContract, marketplaceContract, tokenId, initialShares,
        owner, user1, user2,
        listingPrice
    }
  };

  it("Should allow the marketplace contract mint new NFT", async function () {
    const {marketplaceContract, tokenId, user1, listingPrice } = await deployFixture()
    const mintTx = await marketplaceContract.mintAsset(user1, 0, "new asset");
    await expect(mintTx).to.emit(marketplaceContract, "Mint")
  } )

  // it("Should allow the owner to create listings", async function () {
  //   const {marketplaceContract, tokenId, user1, listingPrice } = await deployFixture()
  //   const listingTx = await marketplaceContract.connect(user1).createListing(tokenId, listingPrice);
  //   const listingId = 0;
  //   await expect(
  //     listingTx
  //   ).to.emit(marketplaceContract, "ListingCreated")
  //     .withArgs(listingId, user1.address, tokenId, listingPrice);
  // });

  it("Should allow a user to buy NFT shares", async function () {
    const {marketplaceContract, nftContract, tokenId, owner, user1, user2, listingPrice, erc20TokenContract } = await deployFixture()
    await marketplaceContract.mintAsset(user1, tokenId, "new asset");
    await nftContract.setApprovalForAll(marketplaceContract.target, true);

    console.log('user token balance:', await nftContract.balanceOf(user1, tokenId))
    await marketplaceContract.connect(user1).createListing(tokenId, listingPrice)

    await marketplaceContract.connect(user2).buyShare(user1.address, tokenId, 10000);
    console.log('shares', await marketplaceContract.getSharesOwned(user2.address, tokenId))
    // const userBalance = await nftContract.balanceOf(user1.address);
    // expect(userBalance).to.equal(1);
  });

  // Add more test cases for other scenarios
});
