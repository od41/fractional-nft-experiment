// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketplaceOld is Ownable {
    IERC721 public nftToken; // The ERC721 token being sold
    IERC20 public paymentToken; // The ERC20 token used for payments

    uint256 public listingPrice; // Price in paymentToken per listing
    uint256 public nextListingId;

    struct Listing {
        uint256 id;
        address seller;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    struct Asset {
        uint256 tokenId;
        address[] owners;
        bool isListed;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => mapping(address => uint256)) private sharesOwned;
    // pass a tokenId and address and get back the number of shares the address owns of an asset

    struct TokenShare {
        uint256 tokenId;
        uint256 share; // Percentage share (e.g., 100% = 10000)
    }

    TokenShare[] public tokenShares;

    event ListingCreated(uint256 indexed id, address indexed seller, uint256 indexed tokenId, uint256 price);
    event ListingCancelled(uint256 indexed id);
    event ListingSold(uint256 indexed id, address indexed seller, address indexed buyer, uint256 price);

    event Mint(uint256 indexed tokenId, address indexed owner);

    constructor(
        address _nftToken,
        address _paymentToken,
        uint256 _listingPrice
    ) {
        nftToken = IERC721(_nftToken);
        paymentToken = IERC20(_paymentToken);
        listingPrice = _listingPrice;
    }

    function createListing(uint256 _tokenId, uint256 _price) external {
        require(_price >= listingPrice, "Price is lower than the listing price");
        require(nftToken.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");

        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            id: listingId,
            seller: msg.sender,
            tokenId: _tokenId,
            price: _price,
            active: true
        });

        nftToken.transfer(msg.sender, address(this), _tokenId);
        emit ListingCreated(listingId, msg.sender, _tokenId, _price);
    }

    function cancelListing(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "You are not the seller");
        require(listing.active, "Listing is not active");

        listing.active = false;
        nftToken.transfer(address(this), msg.sender, listing.tokenId);
        emit ListingCancelled(_listingId);
    }

    function buyListing(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.active, "Listing is not active");
        require(paymentToken.transferFrom(msg.sender, address(this), listing.price), "Payment failed");

        listing.active = false;
        nftToken.transfer(address(this), msg.sender, listing.tokenId); 
        emit ListingSold(_listingId, listing.seller, msg.sender, listing.price);
    }

    function setListingPrice(uint256 _newPrice) external onlyOwner {
        listingPrice = _newPrice;
    }

    function addTokenShare(uint256 _tokenId, uint256 _share) internal onlyOwner {
        require(_share <= 10000, "Share should be in the range [0, 10000]"); // Percentage

        tokenShares.push(TokenShare({
            tokenId: _tokenId,
            share: _share
        }));
    }

    function removeTokenShare(uint256 _index) internal onlyOwner {
        require(_index < tokenShares.length, "Index out of bounds");
        tokenShares[_index] = tokenShares[tokenShares.length - 1];
        tokenShares.pop();
    }

    // add a mint function
    function mintAsset(address to, string memory uri) external onlyOwner {
        uint256 newTokenId = nftToken.safeMint(to, uri);
        addTokenShare(newTokenId, 10000);

        emit Mint(newTokenId, to);
    }

    function buyShare(uint256 _tokenId, uint256 _amount) external {
        TokenShare storage share = tokenShares[_tokenId];

        uint256 totalPrice = (_amount * share.share) / 10000; // Calculate the price in tokens
        require(paymentToken.transferFrom(msg.sender, address(this), totalPrice), "Token transfer failed");

        nftToken.transferFrom(address(this), msg.sender, share.tokenId); // Transfer NFT

        // You can implement additional logic here, like tracking ownership and distributing royalties.
    }
}
