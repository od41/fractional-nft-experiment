import { expect } from "chai";
import { ethers } from "hardhat";

describe("NFTFractionalOwnership", function () {

  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();

    const NFTContract = await ethers.getContractFactory("TestNFT");
    const nftContract = await NFTContract.deploy();

    await nftContract.safeMint(nftContract.target, "simple nft")

    const ERC20TokenContract = await ethers.getContractFactory("TestCoins");
    const erc20TokenContract = await ERC20TokenContract.deploy();
    
    const NFTFractionalOwnership = await ethers.getContractFactory("NFTFractionalOwnership");
    const nftFractionalContract = await NFTFractionalOwnership.deploy(nftContract.target, erc20TokenContract.target);

    const tokenId = 1;
    const initialShares = [{ tokenId, share: 5000 }];

    return {
        nftContract, erc20TokenContract, nftFractionalContract, tokenId, initialShares,
        owner, user1, user2
    }
  };

  it("Should allow the owner to add NFT shares", async function () {
    const {nftFractionalContract, tokenId } = await deployFixture()
    await nftFractionalContract.addTokenShare(tokenId, 5000);
    const shares = await nftFractionalContract.tokenShares(0);
    expect(shares.tokenId).to.equal(tokenId);
    expect(shares.share).to.equal(5000);
  });

  it("Should allow a user to buy NFT shares", async function () {
    const {nftFractionalContract, tokenId, user1, user2, erc20TokenContract } = await deployFixture()
    await nftFractionalContract.addTokenShare(0, 10000);

    await erc20TokenContract.connect(user1).approve(nftFractionalContract.target, 2500); 
    // await erc20TokenContract.myTransfer(user1, 5000); // 25% of the share price
    const bal = await erc20TokenContract.balanceOf(user1.address);

    // await nftFractionalContract.connect(user1).buyShare(0, 2500);
    //   console.log('shares', await nftFractionalContract.tokenShares(0))
    // const userBalance = await nftContract.balanceOf(user1.address);
    // expect(userBalance).to.equal(1);
  });

  // Add more test cases for other scenarios
});
