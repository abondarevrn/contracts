pragma solidity >=0.5.16;

import "./PriceOracle.sol";
import "./UniswapOracle.sol";

contract BatchOracle is PriceOracle, Operator {
    struct OracleInfo {
        address oracle;
        address pairA;
        bool enable;
    }
	struct RouterInfo {
        bool enable;
        uint256 underlyingDecimals;
		address oracle;
		address oracle2;
		// uint256 price;
	}
    address public baseToken;
    uint256 public baseUnderlyingDecimals;
	bool public baseEnable;
	uint256 public basePrice;
    mapping(address => uint256) public oraclemap;
	mapping(address => uint256) public routermap;
    OracleInfo[] public oracles;
	RouterInfo[] public routers;
    
    constructor() public {
		// BASE: USDC
        setBaseToken(0x92aF72ec27eb22A966c67a87BE33C342AcC0B77a, 6, true, 10**30);
		
		//Oracles
		// MATIC => USDC (QUICKSWAP)
		updateOracle(0x7cfaaCAaEb82826970B4055E2DeB7483C8b52763, 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, true);
		// DAI => USDC (QUICKSWAP)
		updateOracle(0x0f074688431254B90d9E308a218EAe200041bd96, 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063, true);
		// ETH => USDC (QUICKSWAP)
		updateOracle(0x6Cbe7f5484c9ac53A89ff94161533d673BBe7d34, 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, true);
		// QUICK => USDC (QUICKSWAP)
		updateOracle(0xD775ac43f6EAb60FB2ceCb46135AA8cBF31425Fd, 0x831753DD7087CaC61aB5644b308642cc1c33Dc13, true);
		// BTC => USDC (QUICKSWAP)
		updateOracle(0x1F0cf2cB49Bee5a05da8f82D839c2120ADbe6991, 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6, true);
		// SUSHI => ETH (SUSHISWAP)
		updateOracle(0xc0ae011f79f8CcE53480cA005d9A4dd38779F116, 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a, true);
		// AAVE => ETH (QUICKSWAP)
		updateOracle(0xacd06Ba4Bddfcc18Ce98B62356BB31D50d1B12e2, 0xD6DF932A45C0f255f85145f286eA0b292B21C90B, true);
		// UNI => QUICK (QUICKSWAP)
		updateOracle(0x4427e282d159198ED85C7e48d9eA57465EB4D504, 0xb33EaAd8d922B1083446DC23f610c2567fB5180f, true);
		// LINK => ETH (QUICKSWAP)
		updateOracle(0x8C85d94213654f0b6F1A3763a2f68c0a7EBDACE4, 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39, true);
		// APPLE => USDC (QUICKSWAP)
		updateOracle(0x34602388158469B34A5ECdADC589eDE279fca0AD, 0xda8F20bf431d04a3661250F922D75e2bBE0B001C, true);
		
		//Routers
		// MATIC => USDC
		updateRouter(0x2840AF6f287d329237c8addc5500C349E041C5BB, 18, true, 0x7cfaaCAaEb82826970B4055E2DeB7483C8b52763, address(0));
		// DAI => USDC
		updateRouter(0xB9D5BA34089F35C5e66F480E042B840151a5f10f, 18, true, 0x0f074688431254B90d9E308a218EAe200041bd96, address(0));
		// ETH => USDC
		updateRouter(0x0a5f450e7F75495F73fdB520242aa317C7fDa01f, 18, true, 0x6Cbe7f5484c9ac53A89ff94161533d673BBe7d34, address(0));
		// QUICK => USDC
		updateRouter(0xe500e73E53fF8b8D9228B3cE9Fc7431f622A6849, 18, true, 0xD775ac43f6EAb60FB2ceCb46135AA8cBF31425Fd, address(0));
		// BTC => USDC
		updateRouter(0xeEcc1EE8E978ad35148824C3FDb5C3f80ab5F9F5, 8, true, 0x1F0cf2cB49Bee5a05da8f82D839c2120ADbe6991, address(0));
		// SUSHI => ETH => USDC
		updateRouter(0x860ef75DE5029145B0B64C7Cc7C35e6df533a910, 18, true, 0xc0ae011f79f8CcE53480cA005d9A4dd38779F116, 0x6Cbe7f5484c9ac53A89ff94161533d673BBe7d34);
		// AAVE => ETH => USDC
		updateRouter(0xbCE054D82120cF261Ea6c7F03C6fb04456F59a57, 18, true, 0xacd06Ba4Bddfcc18Ce98B62356BB31D50d1B12e2, 0x6Cbe7f5484c9ac53A89ff94161533d673BBe7d34);
		// UNI => QUICK => USDC
		updateRouter(0xb823A24767aFD8f590d178B101D7190dc2343924, 18, true, 0x4427e282d159198ED85C7e48d9eA57465EB4D504, 0xD775ac43f6EAb60FB2ceCb46135AA8cBF31425Fd);
		// LINK => ETH => USDC
		updateRouter(0x43D897835499a05f6175579a26EAb4B711936396, 18, true, 0x8C85d94213654f0b6F1A3763a2f68c0a7EBDACE4, 0x6Cbe7f5484c9ac53A89ff94161533d673BBe7d34);
		// APPLE => USDC
		updateRouter(0x44154E2de24F43700f7b7cA91085aF13C481E001, 18, true, 0x34602388158469B34A5ECdADC589eDE279fca0AD, address(0));
    }
    
	function checkOracle(address _oracle) public view returns(bool){
		uint256 index = oraclemap[_oracle];
		if (index == 0) {
			return false;
		}
		return oracles[index - 1].enable;
	}
    
    function updateRouter(address _cToken, uint256 _underlyingDecimals, bool _enable, address _oracle, address _oracle2) public {
        if (routermap[_cToken] == 0) {
			routermap[_cToken] = routers.length + 1;
			routers.push(RouterInfo(_enable, _underlyingDecimals, _oracle, _oracle2));
		} else {
			uint256 index = routermap[_cToken] - 1;
			routers[index].enable = _enable;
			routers[index].underlyingDecimals = _underlyingDecimals;
			routers[index].oracle = _oracle;
			routers[index].oracle2 = _oracle2;
		}
    }
	
	function updateOracle(address _oracle, address _pairA, bool _enable) public onlyOperator{
		if (oraclemap[_oracle] == 0) {
            oraclemap[_oracle] = oracles.length + 1; 
            oracles.push(OracleInfo(_oracle, _pairA, _enable));
        } else {
            uint256 index = oraclemap[_oracle] - 1;
            oracles[index].oracle = _oracle;
            oracles[index].enable = _enable;
            oracles[index].pairA = _pairA;
        }
	}
    
    function setBaseToken(address _baseToken, uint256 _baseUnderlyingDecimals, bool _enable, uint256 _basePrice) public onlyOperator {
        baseToken = _baseToken;
        baseUnderlyingDecimals = _baseUnderlyingDecimals;
		baseEnable = _enable;
		basePrice = _basePrice;
    }
    
    function update() external returns(bool){
        for(uint256 i = 0; i < oracles.length; i++){
            OracleInfo memory info = oracles[i];
            if(info.enable){
                require( Oracle(info.oracle).update(), "update failed");
            }
        }
        // for(uint256 i = 0; i < routers.length; i++){
        //     if(routers[i].enable){
        //         routers[i].price = _getPrice(routers[i]);
        //     }
        // }
		return true;
    }
    
    // function getUnderlyingPrice(CToken _cToken) external view returns (uint256) {
    //     if(address(_cToken) == baseToken){
    //         if(!baseEnable){
    //             return 0;
    //         }
    //         return basePrice;
    //     }
    //     uint256 i = routermap[address(_cToken)];
    //     if(i == 0){
    //         return 0;
    //     }
    //     RouterInfo memory router = routers[i-1];
    //     if(!router.enable){
    //         return 0;
    //     }
    //     return router.price;
    // }
    
//     function _getPrice(RouterInfo memory _router) internal view returns (uint256) {
//         uint256 price = 10 ** _router.underlyingDecimals;
// 		if (!checkOracle(_router.oracle)) {
// 			return 0;
// 		}
// 		OracleInfo memory oracle = oracles[oraclemap[_router.oracle] - 1]; 
// 		price = Oracle(_router.oracle).consult(oracle.pairA, price);
// 		if (_router.oracle2 != address(0)) {
// 		    if (!checkOracle(_router.oracle2)) {
// 		    	return 0;
// 		    }
// 		    oracle = oracles[oraclemap[_router.oracle2] - 1];
// 		    price = Oracle(_router.oracle2).consult(oracle.pairA, price);
// 		}
// 		return price * 10 ** (36 - baseUnderlyingDecimals - _router.underlyingDecimals);
//     }
    
    function getUnderlyingPrice(CToken _cToken) external view returns (uint256) {
        if(address(_cToken) == baseToken){
            if(!baseEnable){
                return 0;
            }
            return 10 ** (36 - baseUnderlyingDecimals);
        }
        uint256 i = routermap[address(_cToken)];
        if(i == 0){
            return 0;
        }
        RouterInfo memory router = routers[i-1];
        if(!router.enable){
            return 0;
        }
		uint256 price = 10 ** router.underlyingDecimals;
		if (!checkOracle(router.oracle)) {
			return 0;
		}
		OracleInfo memory oracle = oracles[oraclemap[router.oracle] - 1]; 
		price = Oracle(router.oracle).consult(oracle.pairA, price);
		if (router.oracle2 != address(0)) {
		    if (!checkOracle(router.oracle2)) {
		    	return 0;
		    }
		    oracle = oracles[oraclemap[router.oracle2] - 1];
		    price = Oracle(router.oracle2).consult(oracle.pairA, price);
		}
		return price * 10 ** (36 - baseUnderlyingDecimals - router.underlyingDecimals);
    }
}