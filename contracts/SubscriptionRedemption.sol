// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IPriceOracle {
    function getLatestPriceUSD() external view returns (uint256); // 返回cents格式
}

contract SubscriptionRedemption {
    IERC20 public usdtToken;
    IERC20 public token0050t;
    IPriceOracle public priceOracle;
    address public issuer; // 發行方地址
    
    // 最小申購贖回金額（避免dust攻擊）
    uint256 public constant MIN_SUBSCRIPTION_USD = 100; // $1.00 (100 cents)
    uint256 public constant MIN_REDEMPTION_SHARES = 1; // 1股
    
    event Subscription(address indexed user, uint256 usdtAmount, uint256 sharesReceived);
    event Redemption(address indexed user, uint256 sharesRedeemed, uint256 usdtAmount);
    
    constructor(
        address _usdtToken,
        address _token0050t,
        address _priceOracle,
        address _issuer
    ) {
        usdtToken = IERC20(_usdtToken);
        token0050t = IERC20(_token0050t);
        priceOracle = IPriceOracle(_priceOracle);
        issuer = _issuer;
    }
    
    // 申購：用 USDt 買 0050t
    function subscribe(uint256 usdtAmountCents) external {
        require(usdtAmountCents >= MIN_SUBSCRIPTION_USD, "Amount too small");
        
        // 1. 獲取0050價格（cents格式）
        uint256 price0050Cents = priceOracle.getLatestPriceUSD();
        require(price0050Cents > 0, "Invalid price");
        
        // 2. 計算可購買的股數（整數股）
        uint256 sharesToBuy = usdtAmountCents / price0050Cents;
        require(sharesToBuy > 0, "Insufficient amount for 1 share");
        
        // 3. 計算實際需要的USDt金額
        uint256 actualUsdtNeeded = sharesToBuy * price0050Cents;
        
        // 4. 從用戶轉USDt到發行方
        require(
            usdtToken.transferFrom(msg.sender, issuer, actualUsdtNeeded),
            "USDt transfer failed"
        );
        
        // 5. 發行方轉0050t給用戶
        require(
            token0050t.transferFrom(issuer, msg.sender, sharesToBuy),
            "0050t transfer failed"
        );
        
        emit Subscription(msg.sender, actualUsdtNeeded, sharesToBuy);
    }
    
    // 贖回：用 0050t 換回 USDt
    function redeem(uint256 sharesToRedeem) external {
        require(sharesToRedeem >= MIN_REDEMPTION_SHARES, "Amount too small");
        
        // 1. 獲取0050價格（cents格式）
        uint256 price0050Cents = priceOracle.getLatestPriceUSD();
        require(price0050Cents > 0, "Invalid price");
        
        // 2. 計算應付的USDt金額
        uint256 usdtToReturn = sharesToRedeem * price0050Cents;
        
        // 3. 從用戶轉0050t到發行方
        require(
            token0050t.transferFrom(msg.sender, issuer, sharesToRedeem),
            "0050t transfer failed"
        );
        
        // 4. 發行方轉USDt給用戶
        require(
            usdtToken.transferFrom(issuer, msg.sender, usdtToReturn),
            "USDt transfer failed"
        );
        
        emit Redemption(msg.sender, sharesToRedeem, usdtToReturn);
    }
    
    // 計算申購預覽：輸入USDt金額，返回可購買的股數
    function previewSubscription(uint256 usdtAmountCents) external view returns (
        uint256 sharesToReceive,
        uint256 actualUsdtNeeded,
        uint256 price0050Cents
    ) {
        price0050Cents = priceOracle.getLatestPriceUSD();
        if (price0050Cents == 0) return (0, 0, 0);
        
        sharesToReceive = usdtAmountCents / price0050Cents;
        actualUsdtNeeded = sharesToReceive * price0050Cents;
    }
    
    // 計算贖回預覽：輸入股數，返回可獲得的USDt
    function previewRedemption(uint256 shares) external view returns (
        uint256 usdtToReceive,
        uint256 price0050Cents
    ) {
        price0050Cents = priceOracle.getLatestPriceUSD();
        if (price0050Cents == 0) return (0, 0);
        
        usdtToReceive = shares * price0050Cents;
    }
    
    // 檢查用戶餘額
    function getUserBalances(address user) external view returns (
        uint256 usdtBalance,
        uint256 shares0050t
    ) {
        return (
            usdtToken.balanceOf(user),
            token0050t.balanceOf(user)
        );
    }
    
    // 檢查發行方餘額
    function getIssuerBalances() external view returns (
        uint256 usdtBalance,
        uint256 shares0050t
    ) {
        return (
            usdtToken.balanceOf(issuer),
            token0050t.balanceOf(issuer)
        );
    }
    
    // 獲取當前價格信息
    function getCurrentPriceInfo() external view returns (
        uint256 price0050Cents,
        string memory priceDisplay
    ) {
        price0050Cents = priceOracle.getLatestPriceUSD();
        
        // 格式化顯示價格 (cents -> dollars)
        uint256 dollars = price0050Cents / 100;
        uint256 cents = price0050Cents % 100;
        
        if (cents < 10) {
            priceDisplay = string(abi.encodePacked("$", _toString(dollars), ".0", _toString(cents)));
        } else {
            priceDisplay = string(abi.encodePacked("$", _toString(dollars), ".", _toString(cents)));
        }
    }
    
    // 輔助函數：uint轉字串
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
}