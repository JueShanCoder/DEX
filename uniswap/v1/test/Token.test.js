const { expect } = require("chai");

describe("Token", () => {
    let owner;
    let token;

    before(async () => {
        [owner] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Test Token", "TKN", 31337);
        await token.deployed();
    });

    it('sets name and symbol when created', async () => {
        expect(await token.name()).to.eq("Test Token");
        expect(await token.symbol()).to.eq("TKN");
    });

    it('mints initialSupply to msg.sender when created', async () => {
        expect(await token.totalSupply()).to.eq(31337);
        expect(await token.balanceOf(owner.address)).to.eq(31337);
    });
});