// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";

contract BasicLiquidity {
    IERC20 private firstToken;
    IERC20 private secondToken;

    uint256 private firstTokenBalance;
    uint256 private secondTokenBalance;

    uint256 private totalLiquidityTokens;
    mapping(address => uint256) public userLiquidity;

    constructor(address _firstToken,address _secondToken) {
        firstToken = IERC20(_firstToken);
        secondToken = IERC20(_secondToken);
    }

    // function checktokenAddress() public view returns(address _appleTokenAddress,address _potatoTokenAddress){
    //     _appleTokenAddress = address(appleToken);
    //     _potatoTokenAddress = address(potatoToken);
    //     return (_appleTokenAddress,_potatoTokenAddress);
    // }

    function _mint(address _to,uint256 _amount) private {
        userLiquidity[_to] += _amount;
        totalLiquidityTokens += _amount;
    }

    function getBothTokenBalance() public view returns(uint256 _firstTokenBalance,uint256 _secondTokenBalance){
        _firstTokenBalance = firstTokenBalance;
        _secondTokenBalance = secondTokenBalance;
    }

    function updateTokenBalance(uint256 _firstTokenBalance,uint256 _secondTokenBalance) private {
        firstTokenBalance = _firstTokenBalance;
        secondTokenBalance = _secondTokenBalance;
    }

    function addLiquidity(uint256 _amountFirstTokens,uint256 _amountSecondTokens) public  returns(uint256 _liquidityTokens){
        require(firstToken.transferFrom(msg.sender,address(this),_amountFirstTokens * 1 ether),"Transfer Failed");
        require(secondToken.transferFrom(msg.sender,address(this),_amountSecondTokens * 1 ether),"Transfer Failed");
        (uint256 _firstTokenBalance, uint256 _secondTokenBalance) = getBothTokenBalance();

        if (_firstTokenBalance > 0 || _secondTokenBalance > 0) {
            require(_amountFirstTokens * _secondTokenBalance == _amountSecondTokens * _firstTokenBalance,"Stable Liquidity value not provided");
        }

        uint256 _totalLiquidityTokens = totalLiquidityTokens;

        if (_totalLiquidityTokens == 0) {
            _liquidityTokens = sqrt(_amountFirstTokens * _amountSecondTokens);
        }
        require(_liquidityTokens > 0,"No Tokens minted");
        _mint(msg.sender, _liquidityTokens);
        updateTokenBalance(firstToken.balanceOf(address(this)),secondToken.balanceOf(address(this)));
    }

    function swapTokens(address _tokenExchange,uint256 _tokenExchangeInAmount) public returns(uint256 _amountOut) {
        require(_tokenExchange == address(firstToken) || _tokenExchange == address(secondToken),"Invalid Token Address");
        bool isWhichToken = (_tokenExchange == address(firstToken));

        (uint256 _firstTokenBalance,uint256 _secondTokenBalance) = getBothTokenBalance();

        (IERC20 _firstToken,IERC20 _secondToken,uint256 firstTokenBalance_,uint256 _secondTokenBalance_) = isWhichToken ? 
        (firstToken,secondToken,_firstTokenBalance,_secondTokenBalance) : 
        (secondToken,firstToken,_secondTokenBalance,_firstTokenBalance);
        require(_tokenExchangeInAmount > 0,"provide valid amount");

        _firstToken.transferFrom(msg.sender,address(this),_tokenExchangeInAmount);
        uint256 tokenAmountWithFees;

        // x * y = k -> part calculation
        (_tokenExchange == address(firstToken)) ? 
        (tokenAmountWithFees = secondTokenBalance - ((firstTokenBalance_ * _secondTokenBalance_) / (firstTokenBalance_ + _tokenExchangeInAmount))) : 
        (tokenAmountWithFees = firstTokenBalance - ((firstTokenBalance_ * _secondTokenBalance_) / (firstTokenBalance_ + _tokenExchangeInAmount)));
        
        _amountOut = tokenAmountWithFees;
        require(_amountOut < secondTokenBalance || _amountOut < firstTokenBalance,"Insufficient Liquidity");
        _secondToken.transfer(msg.sender,_amountOut);
        updateTokenBalance(_firstToken.balanceOf(address(this)),_secondToken.balanceOf(address(this)));
    }

    function sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

}
