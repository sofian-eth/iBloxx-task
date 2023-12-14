const { ethers } = require("ethers");
const ABI = require("../ABI/Marketplace_ABI.json");

const CONTRACT_ADDRESS = "ENTER THE MARKETPLACE CONTRACT ADDRESS";
const provider = new ethers.providers.JsonRpcProvider(process.env.GOR_RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet);

async function createMarketItem(nftContract, tokenId, price) {
  try {
    const tx = await contract.createMarketItem(nftContract, tokenId, price);
    await tx.wait();
    console.log("Market item created!");
  } catch (error) {
    console.error("Error creating market item:", error);
  }
}

async function createAuctionItem(nftContract, tokenId, price, endTime) {
  try {
    const tx = await contract.createAuctionItem(
      nftContract,
      tokenId,
      price,
      endTime
    );
    await tx.wait();
    console.log("Auction item created!");
  } catch (error) {
    console.error("Error creating auction item:", error);
  }
}

async function fixBuy(itemId) {
  try {
    const tx = await contract.fixBuy(itemId, {
      value: ethers.parseEther("0.01"),
    }); // Update with the value in ethers
    await tx.wait();
    console.log("Item bought successfully!");
  } catch (error) {
    console.error("Error buying item:", error);
  }
}

async function bid(itemId, bidValue) {
  try {
    const tx = await contract.bid(itemId, { value: bidValue });
    await tx.wait();
    console.log("Bid placed successfully!");
  } catch (error) {
    console.error("Error placing bid:", error);
  }
}

async function claim(itemId) {
  try {
    const tx = await contract.claim(itemId);
    await tx.wait();
    console.log("Item claimed successfully!");
  } catch (error) {
    console.error("Error claiming item:", error);
  }
}

async function fetchFixPriceItems() {
  try {
    const items = await contract.fetchFixPriceItems();
    console.log("Fixed price items:", items);
    return items;
  } catch (error) {
    console.error("Error fetching fixed price items:", error);
  }
}

async function fetchAuctionItems() {
  try {
    const items = await contract.fetchAuctionItems();
    console.log("Auction items:", items);
    return items;
  } catch (error) {
    console.error("Error fetching Auction items:", error);
  }
}

async function auctionEndTime(itemId) {
  try {
    const endTime = await contract.auctionEndTime(itemId);
    console.log("Auction end time for item", itemId, "is:", endTime.toString());
    return endTime.toString();
  } catch (error) {
    console.error("Error fetching auction end time:", error);
  }
}

async function allBidders(itemId) {
  try {
    const bidders = await contract.allBidders(itemId);
    console.log("Bidders for item", itemId, ":", bidders);
    return bidders;
  } catch (error) {
    console.error("Error fetching bidders:", error);
  }
}

async function mint(address_to, amount) {
  try {
    const mint = await contract.mint(address_to, amount);
    console.log(`Items minted successfully!`);
  } catch (error) {
    console.error("Error minting: ", error);
  }
}

// createMarketItem('NFT_CONTRACT_ADDRESS (0x.........)', 1, ethers.parseEther('0.01'));
// createAuctionItem('NFT_CONTRACT_ADDRESS (0x..........)', 2, ethers.parseEther('0.05'), 1703514316);
// fixBuy(1);
// bid(2, ethers.parseEther('0.05'));
// claim(2);
// fetchFixPriceItems()
// fetchAuctionItems()
// auctionEndTime(1)
// allBidders(2)
