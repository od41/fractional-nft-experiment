// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC1155.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    IERC1155 public nftToken; // The ERC721 token being sold
    IERC20 public paymentToken; // The ERC20 token used for payments

    uint256 public listingPrice; // Price in paymentToken per listing
    uint256 public nextListingId;
    uint constant COMPLETELY_OWNED = 10000;

    struct Listing {
        uint256 id;
        address seller;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    struct Asset {
        uint256 tokenId;
        uint256 price;
        address[] owners;
        mapping(address => uint) shares;
        bool isListed;
    }

    mapping(uint256 => Listing) public listings;

    // pass a tokenId and address and get back the number of shares the address owns of an asset
    mapping(uint256 => mapping(address => uint256)) private sharesOwned;

    Asset[] private assets;

    event ListingCreated(uint256 indexed id, address indexed seller, uint256 indexed tokenId, uint256 price);
    event ListingCancelled(uint256 indexed id);
    event ListingSold(uint256 indexed id, address indexed seller, address indexed buyer, uint256 price);

    event Mint(uint256 indexed tokenId);

    constructor(
        address _nftToken,
        address _paymentToken,
        uint256 _listingPrice
    ) {
        nftToken = IERC1155(_nftToken);
        paymentToken = IERC20(_paymentToken);
        listingPrice = _listingPrice;
    }

    function createListing(uint256 _tokenId, uint256 _price) external {
        require(_price >= listingPrice, "Price is lower than the listing price");

        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            id: listingId,
            seller: msg.sender,
            tokenId: _tokenId,
            price: _price,
            active: true
        });

        emit ListingCreated(listingId, msg.sender, _tokenId, _price);
    }

    function cancelListing(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "You are not the seller");
        require(listing.active, "Listing is not active");

        listing.active = false;
        
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

    // add a mint function
    function mintAsset(address _owner, uint256 _tokenId, string memory _data) external onlyOwner {
        // always mint to the Marketplace contract
        nftToken.mint(_owner, _tokenId, 1, bytes(_data));

        uint posx = assets.length;
        assets.push();
        Asset storage asset = assets[posx];
        asset.tokenId = _tokenId;
        asset.owners = [_owner];
        asset.price = 0;
        asset.shares[_owner] = COMPLETELY_OWNED;
        asset.isListed = false;

        emit Mint(_tokenId);
    }

    function _ownerOf(address _account, uint256 _tokenId) public view returns (bool) {
        return nftToken.balanceOf(_account, _tokenId) != 0;
    }

    function buyShare(address _seller, uint256 _tokenId, uint256 _shares) external {
        address buyer = msg.sender;

        // get the seller
        require(_ownerOf(_seller, _tokenId), "Seller can't sell that token");

        // get the asset
        Asset storage listedAsset = assets[_tokenId];

        // Calculate the price in tokens
        uint pricePerShare = listedAsset.price / 10000;
        uint256 totalPrice = (_shares * pricePerShare) / 10000; 

        // verify the amount that's about to be sent
        require(paymentToken.balanceOf(buyer) >= totalPrice, "You don't have enough coins to buy this");

        // transfer from seller to buyer
        require(paymentToken.transferFrom(buyer, _seller, totalPrice), "Token transfer failed");

        sharesOwned[_tokenId][buyer] = _shares;
        nftToken.setApprovalForAll(buyer, true);
        nftToken.safeTransferFrom(_seller, buyer, _tokenId, 1, bytes("data")); // Transfer NFT

        // You can implement additional logic here, like tracking ownership and distributing royalties.
    }

    function getSharesOwned(address _account, uint256 _tokenId) public view returns(uint256) {
        return sharesOwned[_tokenId][_account];
    }
}
