// require("@nomiclabs/hardhat-waffle")
const { expect } = require("chai");

const toWei = (value) => ethers.utils.parseEther(value.toString());

describe("Factory", () => {
    let owner;
    let factory;
    let token;

    beforeEach(async () => {
        [owner] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN", toWei(1000000));
        await token.deployed();

        const Factory = await ethers.getContractFactory("Factory");
        factory = await Factory.deploy();
        await factory.deployed();
    });

    it('is deployed',  async () => {
        expect(await factory.deployed()).to.eq(factory);
    });

    describe("createExchange", () => {
        it('deploys an exchange', async () => {
            // 模拟调用，验证是否会成功
            const exchangeAddress = await factory.callStatic.createExchange(token.address);
            console.log("exchangeAddress", exchangeAddress)
            await factory.createExchange(token.address);


            expect(await factory.tokenToExchange(token.address)).to.eq(exchangeAddress);

            const Exchange = await ethers.getContractFactory("Exchange");
            const exchange = await Exchange.attach(exchangeAddress);
            expect(await exchange.name()).to.eq("Zuniswap-V1");
            expect(await exchange.symbol()).to.eq("ZUNI-V1");
            expect(await exchange.factoryAddress()).to.eq(factory.address);
        });

        it('is deployed', async () => {
            expect(await factory.deployed()).to.eq(factory);
        });

        it("doesn't allow zero address", async () => {
            await expect(
                factory.createExchange("0x0000000000000000000000000000000000000000")
            ).to.be.revertedWith("invalid token address");
        });

        it('fails when exchange exists', async () => {
            const exchangeAddress = await factory.callStatic.createExchange(
                token.address
            );
            await factory.createExchange(token.address);

            expect(await factory.getExchange(token.address)).to.equal(
                exchangeAddress
            );
        });
    });

    describe("getExchange", () => {
        it("returns exchange address by token address", async () => {
            const exchangeAddress = await factory.callStatic.createExchange(
                token.address
            );
            await factory.createExchange(token.address);

            expect(await factory.getExchange(token.address)).to.equal(
                exchangeAddress
            );
        });
    });
});