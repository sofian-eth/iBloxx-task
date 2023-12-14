//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./counters.sol";

contract Marketplace is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721Upgradeable
{
    event MarketItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId,
        address seller,
        address owner,
        uint price,
        bool sold
    );
    event AuctionItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId,
        address seller,
        address owner,
        uint listingTime,
        uint endTime,
        uint price,
        bool sold
    );

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint tokenId;
        address payable seller;
        address payable owner;
        uint listingTime;
        uint endTime;
        uint price;
        bool sold;
        uint highestBid;
        address payable highestBidder;
        address[] allBidders;
    }
    mapping(uint => MarketItem) private idToMarketItem;

    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        __ERC721_init(name, symbol);
        __AccessControl_init();

        _grantRole(MINTER_ROLE, 0xFbB28e9380B6657b4134329B47D9588aCfb8E33B);
    }

    function createMarketItem(
        address _nftContract,
        uint tokenId,
        uint price
    ) public nonReentrant {
        require(price > 0, "Price must be at least 1 wei");

        _itemIds.increment();
        uint itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            _nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            0,
            0,
            price,
            false,
            0,
            payable(address(0)),
            new address[](0)
        );
        IERC721(_nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            itemId,
            _nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    function createAuctionItem(
        address _nftContract,
        uint tokenId,
        uint price,
        uint _endTime
    ) public nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        require(
            _endTime > block.timestamp,
            "Auction can not last more than 7 days"
        );

        _itemIds.increment();
        uint itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            _nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            block.timestamp,
            _endTime,
            price,
            false,
            price,
            payable(address(0)),
            new address[](0)
        );
        IERC721(_nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit AuctionItemCreated(
            itemId,
            _nftContract,
            tokenId,
            msg.sender,
            address(0),
            block.timestamp,
            _endTime,
            price,
            false
        );
    }

    function fixBuy(uint itemId) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        uint highestBid = idToMarketItem[itemId].highestBid;

        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        require(
            highestBid == 0,
            "This item is listed for auction and cannot be purchased directly"
        );

        address nftAddress = idToMarketItem[itemId].nftContract;

        idToMarketItem[itemId].seller.transfer(msg.value);
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
    }

    function bid(uint itemId) public payable nonReentrant {
        uint privHighestBid = idToMarketItem[itemId].highestBid;
        address payable privHighestBidder = idToMarketItem[itemId]
            .highestBidder;
        uint endTime = idToMarketItem[itemId].endTime;

        require(block.timestamp < endTime, "Auction has ended");
        require(
            privHighestBid > 0 && msg.value > privHighestBid,
            "Your bid is lower than the highest bid"
        );

        idToMarketItem[itemId].highestBidder = payable(msg.sender);
        idToMarketItem[itemId].highestBid = msg.value;
        idToMarketItem[itemId].endTime += 15 minutes;
        idToMarketItem[itemId].allBidders.push(msg.sender);

        if (privHighestBidder != address(0)) {
            privHighestBidder.transfer(privHighestBid);
        }
    }

    function claim(uint itemId) external nonReentrant {
        uint highestBid = idToMarketItem[itemId].highestBid;
        uint tokenId = idToMarketItem[itemId].tokenId;
        address highestBidder = idToMarketItem[itemId].highestBidder;
        uint endTime = idToMarketItem[itemId].endTime;

        require(
            msg.sender == highestBidder,
            "You are not the highest bidder for this item"
        );
        require(block.timestamp > endTime, "The Auction hasn't ended yet");

        address nftAddress = idToMarketItem[itemId].nftContract;

        idToMarketItem[itemId].seller.transfer(highestBid);
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function fetchFixPriceItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].highestBid == 0) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchAuctionItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].highestBid > 0) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function auctionEndTime(uint itemId) public view returns (uint) {
        return idToMarketItem[itemId].endTime;
    }

    function allBidders(uint itemId) public view returns (address[] memory) {
        return idToMarketItem[itemId].allBidders;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
