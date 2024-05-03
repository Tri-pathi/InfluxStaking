const hre = require("hardhat");

const main = async () => {
  //Deploying Testing  Staking ERC20

  const stakingToken= await hre.ethers.deployContract("StakingToken");
  await stakingToken.waitForDeployment();
  console.log("Staking Token deployed at ",stakingToken.target);


  // Deploying InfluxStaking

  const influxStaking = await hre.ethers.deployContract("InfluxStaking",[
    stakingToken.target,
  ]);


  await influxStaking.waitForDeployment();

  console.log("Influx Staking deployed at ",influxStaking.target);



  

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });