const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

const main = async () => {
  [owner, addr1, addr2] = await ethers.getSigners();
  const name = "IBLOXX";
  const symbol = "IXX";

  const DummyERC721 = await ethers.getContractFactory("DummyERC721");
  console.log(`Deploying dummy ERC721 contract...`);
  const dummyerc721 = await DummyERC721.deploy();
  await dummyerc721.waitForDeployment();

  console.log(`Deployed to ${dummyerc721.target}`);

  console.log(`Now deploying upgradable marketplace...`);

  const Marketplace = await ethers.getContractFactory("Marketplace");

  const marketplace = await upgrades.deployProxy(Marketplace, [name, symbol], {
    initializer: "initialize",
  });
  await marketplace.waitForDeployment();

  console.log(`Marketplace deployed to ${marketplace.target}`);

  console.log(`Approving ERC721 tokens to be listed on marketplace...`);

  const tx1 = await dummyerc721.approve(marketplace.target, "0");
  await tx1.wait();
  const tx2 = await dummyerc721.approve(marketplace.target, "1");
  await tx2.wait();
  const tx3 = await dummyerc721.approve(marketplace.target, "2");
  await tx3.wait();

  console.log(`Approved ERC721 Tokens successfully!`);

  console.log(`Listing ERC721 Tokens for fix buy...`);

  const fixBuy = await marketplace.createMarketItem(
    dummyerc721.target,
    1,
    ethers.parseEther("0.01")
  );
  await fixBuy.wait();

  console.log(`ERC721 token listed for fix price buy successfully!`);
  console.log(`Now listing one for auction...`);

  const auctionBuy = await marketplace.createAuctionItem(
    dummyerc721.target,
    2,
    ethers.parseEther("0.03"),
    1703514316
  );
  await auctionBuy.wait();

  console.log(`ERC721 Listed for auction successfully!`);
  console.log(`Now attempting to buy it...`);

  const buyNow = await marketplace
    .connect(addr1)
    .fixBuy(1, { value: ethers.parseEther("0.01") });
  await buyNow.wait();

  console.log(`ERC721 Token bought off the marketplace successfully!`);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
