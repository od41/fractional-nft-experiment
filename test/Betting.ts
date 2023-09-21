import { expect } from 'chai';
import { ethers } from 'hardhat';
import { BettingContract, BetState } from "../typechain-types";

describe('BettingContract', function () {
  let bettingContract: BettingContract;
  let owner: any;

  before(async () => {
    [owner] = await ethers.getSigners();
    const BettingContractFactory = await ethers.getContractFactory('BettingContract');
    bettingContract = await BettingContractFactory.deploy();
    // await bettingContract.deployed();
  });

  it('should create a game', async (done) => {
    await bettingContract.createGame('Test Game');
    // const numGames = await bettingContract.numGames();
    // done()
    // expect(numGames).to.equal(1);
  });

});