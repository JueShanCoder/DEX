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
            await token.approve(exchange.address, toWei(300));
            await exchange.addLiquidity(toWei(200), { value: toWei(100) });

            expect(await getBalance(exchange.address)).to.eq(toWei(100));
            expect(await exchange.getReserve()).to.eq(toWei(200));

            // test for addLiquidity
            await exchange.addLiquidity(toWei(100), { value: toWei(50) });
            // token Amount = 50 * 200 / 100
            // liquidity Amount = 50 * 100 / 100
            expect(await getBalance(exchange.address)).to.eq(toWei(150));
            expect(await exchange.getReserve()).to.eq(toWei(300));
            expect(await exchange.totalSupply()).to.eq(toWei(150));
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
            ).to.equal("24.99993502714336466"); // 25 - gas fees

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
            ).to.equal("99.9999486339558373"); // 100 - gas fees

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

            expect(await exchange.getReserve()).to.equal(toWei(0));
            expect(await getBalance(exchange.address)).to.equal(toWei(0));
            expect(fromWei(await token.balanceOf(user.address))).to.equal(
                "18.165287753432130193"
            );

            const userEtherBalanceAfter = await getBalance(owner.address);
            const userTokenBalanceAfter = await token.balanceOf(owner.address);

            expect(
                fromWei(userEtherBalanceAfter.sub(userEtherBalanceBefore))
            ).to.equal("109.99994900591381861"); // 110 - gas fees

            expect(
                fromWei(userTokenBalanceAfter.sub(userTokenBalanceBefore))
            ).to.equal("181.834712246567869807");
        });

        it('burns LP-tokens', async () => {
            await expect(() => exchange.removeLiquidity(toWei(25)))
                .to.changeTokenBalance(exchange, owner, toWei(-25));

            expect(await exchange.totalSupply()).to.equal(toWei(75));
        });

        it("it doesn't allow invalid amount", async () => {
            await expect(
                exchange.removeLiquidity(toWei(100.1))).to.be.revertedWith(
                    "ERC20: burn amount exceeds balance"
            );
        });
    });

    describe("getTokenAmount", async () => {
        it('returns correct token amount', async () => {
            await token.approve(exchange.address, toWei(2000));
            await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });
            // ethReserve: 1000
            // tokenReserve: 2000
            // LP-Token: 1000

            let tokensOut = await exchange.getTokenAmount(toWei(1));
            // tokensOut = (1 * 999 * 2000) / (1000 * 1000 + 1 * 999) = 1998000 / 1000999 = 1.996005990015974041
            expect(fromWei(tokensOut)).to.equal("1.996005990015974041");

            tokensOut = await exchange.getTokenAmount(toWei(100));
            // tokensOut = (100 * 999 * 2000) / (1000 * 1000 + 100 * 999) = 199800000 / 1099900 = 181.652877534321302
            expect(fromWei(tokensOut)).to.eq("181.652877534321301936");

            tokensOut = await exchange.getTokenAmount(toWei(1000));
            // tokensOut = (1000 * 999 * 2000) / (1000 * 1000 + 1000 * 999) = 1998000000 / 1999000 = 999.499749874937469
            expect(fromWei(tokensOut)).to.eq("999.499749874937468734");
        });
    });

    describe("getEthAmount", async () => {
        it('returns correct eth amount', async () => {
            await token.approve(exchange.address, toWei(2000));
            await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });
            // EthReserve: 1000
            // TokenReserve: 2000
            // LP-Token: 1000

            let ethOut = await exchange.getEthAmount(toWei(2));
            // ethOut = (2 * 999 * 1000) / (2000 * 1000 + 2 * 999) = 1998000 / 2001998 = 0.998002995007987
            expect(fromWei(ethOut)).to.equal("0.99800299500798702");

            ethOut = await exchange.getEthAmount(toWei(100));
            // ethOut = (100 * 999 * 1000) / (2000 * 1000 + 100 * 999) = 99900000 / 2099900 = 47.573693985427878
            expect(fromWei(ethOut)).to.equal("47.573693985427877517");

            ethOut = await exchange.getEthAmount(toWei(2000));
            expect(fromWei(ethOut)).to.equal("499.749874937468734367");
        });
    });

    describe("ethToTokenSwap", async () => {
        beforeEach(async () => {
            await token.approve(exchange.address, toWei(2000));
            await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });
            // EthReserve: 1000
            // TokenReserve: 2000
            // LP-Token: 1000
        });

        it('transfers at least min amount of tokens', async () => {
            const userBalanceBefore = await getBalance(user.address);

            await exchange
                .connect(user)
                .ethToTokenSwap(toWei(1.97), { value: toWei(1)});
            let tokensOut = await exchange.getTokenAmount(toWei(1));
            expect(fromWei(tokensOut)).to.eq("1.992023934171565083");
            // inputAmount: 1
            // inputReserve: 1000
            // outputReserve: 2000
            // outputAmount = (1 * 999 * 2000) / (1000 * 999 + 1 * 999) = 1998000 / 999999
            // tokensBought = 1.998001998001998

            const userBalanceAfter = await getBalance(user.address);
            expect(fromWei(userBalanceAfter - userBalanceBefore)).to.eq("-1.0000652661549957");

            const userTokenBalance = await token.balanceOf(user.address);
            expect(fromWei(userTokenBalance)).to.eq("1.996005990015974041");

            const exchangeEthBalance = await getBalance(exchange.address);
            expect(fromWei(exchangeEthBalance)).to.eq("1001.0");

            const exchangeTokenBalance = await token.balanceOf(exchange.address);
            expect(fromWei(exchangeTokenBalance)).to.equal("1998.003994009984025959");
        });

        it('affects exchange rate', async () => {
            let tokenOut = await exchange.getTokenAmount(toWei(10));
            // ethAmount = (10 * 999 * 2000) / (10 * 999 + 1000 * 1000) = 19980000 / 1009990 = 19.782374082911712
            expect(fromWei(tokenOut)).to.eq("19.782374082911711997");

            await exchange
                .connect(user)
                .ethToTokenSwap(toWei(9), { value: toWei(10) });
            tokenOut = await exchange.getTokenAmount(toWei(10));
            // ethAmount = (10 * 999 * (2000 - 19.782374082911711997)) / (10 * 999 + 1010 * 1000) = 19782374.0829117120171 / 1019990 = 19.394674538879509
            expect(fromWei(tokenOut)).to.eq("19.39467453887951058");
        });

        it('fails when output amount is less than min amount', async () => {
            await expect(exchange.connect(user).ethToTokenSwap(toWei(2), { value: toWei(1) }))
                .to.be.revertedWith("Insufficient about amount");
        });
    });

    describe("tokenToEthSwap", async () => {
        beforeEach(async () => {
            await token.transfer(user.address, toWei(22));
            await token.connect(user).approve(exchange.address, toWei(22));

            await token.approve(exchange.address, toWei(2000));
            await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });
            // exchange -> { ethReserve: 1000, tokenReserve: 2022, LP-Token: 1000 }
        });

        it('transfers at least min amount of tokens', async () => {
            const userBalanceBefore = await getBalance(user.address);
            const exchangeBalanceBefore = await getBalance(exchange.address);

            await exchange.connect(user).tokenToEthSwap(toWei(2), toWei(0.9));
            // tokenAmount: (2 * 999 * 1000) / (2000 * 1000 + 2 * 999) = 1998000 / 2001998 = 0.998002995007987

            const userBalanceAfter = await getBalance(user.address);
            expect(fromWei(userBalanceAfter.sub(userBalanceBefore))).to.eq("0.997943897590351475")

            const userTokenBalance = await token.balanceOf(user.address);
            expect(fromWei(userTokenBalance)).to.eq("20.0");

            const exchangeBalanceAfter = await getBalance(exchange.address);
            expect(fromWei(exchangeBalanceAfter.sub(exchangeBalanceBefore))).to.eq("-0.99800299500798702");

            const exchangeTokenBalance = await token.balanceOf(exchange.address);
            expect(fromWei(exchangeTokenBalance)).to.equal("2002.0");
        });

        it('fails when output amount is less than min amount ', async () => {
            await expect(
                exchange.connect(user).tokenToEthSwap(toWei(2), toWei(1.0))
            ).to.be.revertedWith("Insufficient output amount");
        });
    });
});