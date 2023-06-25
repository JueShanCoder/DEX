library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }

    function update (
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint128 liquidityDelts
    ) internal {
        Tick.Info storage tickInfo = self[tick];
        uint128 liquidityBefore = tickInfo.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelts;

        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }

        tickInfo.liquidity = liquidityAfter;
    }
}