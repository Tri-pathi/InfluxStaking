const { assert, expect } = require("chai");
const { ethers, deployments } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
describe("StakingToken", function () {
  let stakingToken;
  let influxStaking;
  let account;
  let alice;
  let bob;

  beforeEach(async () => {
    [account, alice, bob] = await ethers.getSigners();

    //Deploying Testing  Staking ERC20

    stakingToken = await hre.ethers.deployContract("StakingToken");
    await stakingToken.waitForDeployment();
    //console.log("Staking Token deployed at ", stakingToken.target);

    // Deploying InfluxStaking

    influxStaking = await hre.ethers.deployContract("InfluxStaking", [
      stakingToken.target,
    ]);

    await influxStaking.waitForDeployment();

    // console.log("Influx Staking deployed at ", influxStaking.target);

    //Give alice and bob enough tokens to stake and play with contracts

    const mintingAmount = ethers.parseEther("10000");
    await stakingToken.mint(alice, mintingAmount);

    await stakingToken.mint(bob, mintingAmount);

    await stakingToken.connect(alice).approve(influxStaking, mintingAmount);

    await stakingToken.connect(bob).approve(influxStaking, mintingAmount);
  });

  describe("stake", function () {
    it("Should revert if staking amount is zero ", async () => {
      /**
       * 1- stake zero amoun and check if function revert for InValid Amount
       */
      await expect(influxStaking.stake(0)).to.be.revertedWith("InvalidAmount");
    });

    it("Should stake and start showing points as the time passes", async () => {
      /**
       *
       * 1. stake 100 tokens for Alice
       * 2. increase time for 10 seconds
       * 3. check if rewards accumulated is 4000 tokens
       */
      const stakingAmount = ethers.parseEther("100");
      await influxStaking.connect(alice).stake(stakingAmount);

      //Move the block for 10 seconds
      await time.increaseTo((await time.latest()) + 10);
      // Now check the rewards point
      assert.equal(
        await influxStaking.connect(alice).PendingRewardsPoints(),
        ethers.parseEther("4000")
      );

      assert.equal(
        await influxStaking.getUserStakedAmount(alice),
        ethers.parseEther("100")
      );
      assert.equal(
        await influxStaking.getUserAccRewardPoints(alice),
        ethers.parseEther("0")
      );

      assert.equal(
        await influxStaking.getUserRewardDebt(alice),
        ethers.parseEther("0")
      );
    });

    it("muliples stake distribute rewards proportionally", async () => {
      /**
       *
       * 1. stake 100 tokens for Alice
       * 2. increase time for 10 seconds
       * 3. stake 100 for Bob
       * 4. check rewards for both at 20th second
       * 5. Alice should get (400 *10 + 200 *10) while Bob should get (200 * 10)
       */
      console.log(await time.latest());
      const stakingAmount = ethers.parseEther("100");
      await influxStaking.connect(alice).stake(stakingAmount);
      await time.increaseTo((await time.latest()) + 10);
      // Now check the rewards point
      console.log(await time.latest());
      await influxStaking.connect(bob).stake(stakingAmount);
      await time.increaseTo((await time.latest()) + 10);
      assert.equal(
        await influxStaking.connect(alice).PendingRewardsPoints(),
        ethers.parseEther("6400") // it should be 6000 but since staking happened at 11th sec hence rewards became 400*11 + 200 * 10
      );
      assert.equal(
        await influxStaking.connect(bob).PendingRewardsPoints(),
        ethers.parseEther("2000")
      );
    });
  });
});
