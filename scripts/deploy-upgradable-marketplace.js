const { ethers, upgrades } = require("hardhat");

const main = async () => {
  const Marketplace = await ethers.getContractFactory("Marketplace");
  console.log(`Deploying marketplace...`);
  const name = "Opensea";
  const symbol = "OS";

  const marketplace = await upgrades.deployProxy(Marketplace, [name, symbol], {
    initializer: "initialize",
  });
  await marketplace.waitForDeployment();

  console.log(`Marketplace deployed to ${marketplace.target}`);
};

main();
