// require("@nomiclabs/hardhat-waffle")
const {expect} = require("chai");

const toWei = (value) => ethers.utils.parseEther(value.toString());

const fromWei = (value) =>
    ethers.utils.formatEther(
        typeof value === "string" ? value : value.toString()
    );

const getBalance = ethers.provider.getBalance;

describe("Exchange", () => {
    let owner;
    let user;
    let exchange;

    beforeEach(async () => {
        // deploy token and exchange contract.
        [owner, user] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("Token", "TKN", toWei(1000000));
        await token.deployed();

        const Exchange = await ethers.getContractFactory("Exchange");
        exchange = await Exchange.deploy(token.address);
        await exchange.deployed();
    });

    // done.
    describe("addLiquidity", async () => {
        it('adds liquidity', async () => {
            await token.approve(exchange.address, toWei(200));
            await exchange.addLiquidity(toWei(200), { value: toWei(100) });

            expect(await getBalance(exchange.address)).to.eq(toWei(100));
            expect(await exchange.getReserve()).to.eq(toWei(200));
        });

        it('mints LP tokens', async () => {
            await token.approve(exchange.address, toWei(200));
            await exchange.addLiquidity(toWei(200), {value: toWei(100)});

            expect(await exchange.balanceOf(owner.address)).to.eq(toWei(100));
            expect(await exchange.totalSupply()).to.eq(toWei(100));
        });
    });

    // done.
    describe("existing reserves", async () => {
        beforeEach(async () => {
            await token.approve(exchange.address, toWei(300));
            await exchange.addLiquidity(toWei(200), { value: toWei(100) });
            // ethReserve: 100,  tokenReserve: 200,  LPToken:100
        });

        it('preserves exchange rate', async () => {
            // ethReserve: 100,  tokenReserve: 200,  LPToken: 100
            await exchange.addLiquidity(toWei(200), { value: toWei(50) });
            // tokenAmount = 50 * 200 / 100 = 100
            // liquidity = 50 * 100 / 100  = 50

            expect(await getBalance(exchange.address)).to.eq(toWei(150));
            expect(await exchange.getReserve()).to.eq(toWei(300));
            expect(await exchange.totalSupply()).to.eq(toWei(150));
        });

        it('mints LP tokens', async () => {
            // ethReserve: 150,  tokenReserve: 300,  LPToken: 150
            await exchange.addLiquidity(toWei(200), { value: toWei(50) });
            // tokenAmount = 50 * 300 / 150 = 100
            // liquidity = 50 * 150 / 150 = 50

            expect(await exchange.balanceOf(owner.address)).to.eq(toWei(150));
            expect(await exchange.totalSupply()).to.eq(toWei(150));
        });

        it('fails when not enough tokens', async () => {
            await expect(
                exchange.addLiquidity(toWei(50), { value: toWei(50) })
            ).to.be.revertedWith("Insufficient token amount");
        });
    });

    describe("removeLiquidity", async () => {
        beforeEach(async () => {
            await token.approve(exchange.address, toWei(300));
            await exchange.addLiquidity(toWei(200), { value: toWei(100) });
            // ethReserve: 100,  tokenReserve: 200,  LPToken: 100
        });

        it('remove some liquidity', async () => {
            const userEtherBalanceBefore = await getBalance(owner.address);
            const userTokenBalanceBefore = await token.balanceOf(owner.address);

            await exchange.removeLiquidity(toWei(25));
            // ethAmount = 100 * 25 / 100 = 25
            // tokenAmount = 200 * 25 / 100 = 50
            // ethReserve: 100 - 25 = 75,  tokenReserve: 200 - 50 = 150, LP = 75
            expect(await exchange.getReserve()).to.eq(toWei(150));
            expect(await getBalance(exchange.address)).to.eq(toWei(75));

            const userEtherBalanceAfter = await getBalance(owner.address);
            const userTokenBalanceAfter = await token.balanceOf(owner.address);

            expect(
                fromWei(userEtherBalanceAfter.sub(userEtherBalanceBefore))
            ).to.equal("24.999934803435243887"); // 25 - gas fees

            expect(
                fromWei(userTokenBalanceAfter.sub(userTokenBalanceBefore))
            ).to.equal("50.0");
        });

        it('remove all liquidity', async () => {
            const userEtherBalanceBefore = await getBalance(owner.address);
            const userTokenBalanceBefore = await token.balanceOf(owner.address);

            await exchange.removeLiquidity(toWei(100));

            expect(await exchange.getReserve()).to.eq(toWei(0));
            expect(await getBalance(exchange.address)).to.eq(toWei(0));

            const userEtherBalanceAfter = await getBalance(owner.address);
            const userTokenBalanceAfter = await token.balanceOf(owner.address);

            expect(
                fromWei(userEtherBalanceAfter.sub(userEtherBalanceBefore))
            ).to.equal("99.99994853939259511"); // 100 - gas fees

            expect(
                fromWei(userTokenBalanceAfter.sub(userTokenBalanceBefore))
            ).to.equal("200.0");
        });

        it('pays for provided liquidity', async () => {
            const userEtherBalanceBefore = await getBalance(owner.address);
            const userTokenBalanceBefore = await token.balanceOf(owner.address);

            await exchange
                .connect(user)
                .ethToTokenSwap(toWei(18), { value: toWei(10) });

            await exchange.removeLiquidity(toWei(100));

            expect(await exchange.getReserve()).to.eq(toWei(0));
            expect(await getBalance(exchange.address)).to.eq(toWei(0));
            // tokensBought = ((10 * 999) * 200) / (90 * 1000 + 10)
            expect(fromWei(await token.balanceOf(user))).to.eq("18.01637852593266606");

        });
    });

    // describe("getTokenAmount", async () => {
    //     it('returns correct token amount', async () => {
    //         await token.approve(exchange.address, toWei(2000));
    //         await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });
    //
    //         let tokensOut = await exchange.getTokenAmount(toWei(1));
    //         expect(fromWei(tokensOut)).to.equal("1.998001998001998001");
    //
    //         tokensOut = await exchange.getTokenAmount(toWei(100));
    //         expect(fromWei(tokensOut)).to.eq("181.818181818181818181");
    //
    //         tokensOut = await exchange.getTokenAmount(toWei(1000));
    //         expect(fromWei(tokensOut)).to.eq("1000.0");
    //     });
    // });
    //
    // describe("getEthAmount", async () => {
    //     it('returns correct eth amount', async () => {
    //         await token.approve(exchange.address, toWei(2000));
    //         await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });
    //
    //         let ethOut = await exchange.getEthAmount(toWei(2));
    //         expect(fromWei(ethOut)).to.equal("0.999000999000999");
    //
    //         ethOut = await exchange.getEthAmount(toWei(100));
    //         expect(fromWei(ethOut)).to.equal("47.619047619047619047");
    //
    //         ethOut = await exchange.getEthAmount(toWei(2000));
    //         expect(fromWei(ethOut)).to.equal("500.0");
    //     });
    // });
    //
    // describe("ethToTokenSwap", async () => {
    //     beforeEach(async () => {
    //         await token.approve(exchange.address, toWei(2000));
    //         await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });
    //     });
    //
    //     it('transfers at least min amount of tokens', async () => {
    //         const userBalanceBefore = await getBalance(user.address);
    //
    //         await exchange
    //             .connect(user)
    //             .ethToTokenSwap(toWei(1.99), { value: toWei(1)});
    //
    //         const userBalanceAfter = await getBalance(user.address);
    //         expect(fromWei(userBalanceAfter - userBalanceBefore)).to.eq("-1.000064711751893");
    //
    //         const userTokenBalance = await token.balanceOf(user.address);
    //         expect(fromWei(userTokenBalance)).to.eq("1.998001998001998001");
    //
    //         const exchangeEthBalance = await getBalance(exchange.address);
    //         expect(fromWei(exchangeEthBalance)).to.eq("1001.0");
    //
    //         const exchangeTokenBalance = await token.balanceOf(exchange.address);
    //         expect(fromWei(exchangeTokenBalance)).to.equal("1998.001998001998001999");
    //
    //     });
    //
    // });


});
