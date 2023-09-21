// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTFractionalOwnership is Ownable {
    IERC721 public nft;
    IERC20 public erc20Token;

    address nftAddress;
    address erc20Address;

    struct TokenShare {
        uint256 tokenId;
        uint256 share; // Percentage share (e.g., 100% = 10000)
    }

    TokenShare[] public tokenShares;

    constructor(address _nftAddress, address _erc20TokenAddress) {
        nft = IERC721(_nftAddress);
        erc20Token = IERC20(_erc20TokenAddress);

        nftAddress = _nftAddress;
        erc20Address = _erc20TokenAddress;
    }

    function addTokenShare(uint256 _tokenId, uint256 _share) external onlyOwner {
        require(_share <= 10000, "Share should be in the range [0, 10000]"); // Percentage

        tokenShares.push(TokenShare({
            tokenId: _tokenId,
            share: _share
        }));
    }

    function removeTokenShare(uint256 _index) external onlyOwner {
        require(_index < tokenShares.length, "Index out of bounds");
        tokenShares[_index] = tokenShares[tokenShares.length - 1];
        tokenShares.pop();
    }

    function buyShare(uint256 _index, uint256 _amount) external {
        require(_index < tokenShares.length, "Index out of bounds");
        TokenShare storage share = tokenShares[_index];

        uint256 totalPrice = (_amount * share.share) / 10000; // Calculate the price in tokens
        require(erc20Token.transferFrom(msg.sender, address(this), totalPrice), "Token transfer failed");

        nft.transferFrom(nftAddress, msg.sender, share.tokenId); // Transfer NFT

        // You can implement additional logic here, like tracking ownership and distributing royalties.
    }
}
