// 使用 Solidity 版本 0.5.3
pragma solidity 0.5.3;

// 导入 OpenZeppelin 的 SafeMath 实现，防止整数溢出
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title 拍卖箱合约
 * @dev 管理多个拍卖合约的创建和访问
 */
contract AuctionBox {
    // 存储拍卖合约地址的数组
    Auction[] public auctions;

    /**
     * @dev 创建一个新的拍卖
     * @param _title 拍卖标题
     * @param _startPrice 起拍价
     * @param _description 拍卖描述
     */
    function createAuction(
        string memory _title,
        uint _startPrice,
        string memory _description
    ) public {
        // 确保起拍价大于 0
        require(_startPrice > 0, "起拍价必须大于 0");

        // 创建新的拍卖实例
        Auction newAuction = new Auction(msg.sender, _title, _startPrice, _description);

        // 将拍卖地址添加到拍卖数组中
        auctions.push(newAuction);
    }

    /**
     * @dev 返回所有拍卖合约地址
     * @return 所有拍卖合约地址的数组
     */
    function returnAllAuctions() public view returns (Auction[] memory) {
        return auctions;
    }
}

/**
 * @title 拍卖合约
 * @dev 管理单个拍卖的逻辑
 */
contract Auction {
    // 使用 SafeMath 库防止整数溢出
    using SafeMath for uint256;

    // 拍卖的状态变量
    address payable private owner; // 拍卖创建者的地址
    string title; // 拍卖标题
    uint startPrice; // 起拍价
    string description; // 拍卖描述

    // 定义拍卖状态枚举
    enum State { Default, Running, Finalized }
    State public auctionState; // 当前拍卖状态

    // 最高出价信息
    uint public highestPrice; // 最高出价金额
    address payable public highestBidder; // 最高出价者地址

    // 映射存储所有出价
    mapping(address => uint) public bids;

    /**
     * @dev 构造函数，用于创建拍卖
     * @param _owner 拍卖创建者的地址
     * @param _title 拍卖标题
     * @param _startPrice 起拍价
     * @param _description 拍卖描述
     */
    constructor(
        address payable _owner,
        string memory _title,
        uint _startPrice,
        string memory _description
    ) public {
        // 初始化拍卖信息
        owner = _owner;
        title = _title;
        startPrice = _startPrice;
        description = _description;
        auctionState = State.Running; // 设置拍卖状态为进行中
    }

    // 修饰符，防止拍卖创建者参与竞标
    modifier notOwner() {
        require(msg.sender != owner, "拍卖创建者不能参与竞标");
        _;
    }

    /**
     * @dev 出价函数
     * @return 如果出价成功返回 true
     */
    function placeBid() public payable notOwner returns (bool) {
        // 确保拍卖正在进行中
        require(auctionState == State.Running, "拍卖已结束或未开始");

        // 确保出价金额大于 0
        require(msg.value > 0, "出价金额必须大于 0");

        // 更新当前用户的总出价
        uint currentBid = bids[msg.sender].add(msg.value);

        // 确保当前出价高于最高出价
        require(currentBid > highestPrice, "出价必须高于当前最高出价");

        // 更新出价记录
        bids[msg.sender] = currentBid;

        // 更新最高出价和最高出价者
        highestPrice = currentBid;
        highestBidder = msg.sender;

        return true;
    }

    /**
     * @dev 结束拍卖并分配资金
     */
    function finalizeAuction() public {
        // 只有拍卖创建者或出价者可以结束拍卖
        require(msg.sender == owner || bids[msg.sender] > 0, "只有拍卖创建者或出价者可以结束拍卖");

        address payable recipient;
        uint value;

        // 根据发送者的身份分配资金
        if (msg.sender == owner) {
            recipient = owner;
            value = highestPrice;
        } else if (msg.sender == highestBidder) {
            recipient = highestBidder;
            value = 0;
        } else {
            recipient = msg.sender;
            value = bids[msg.sender];
        }

        // 清除出价记录
        bids[msg.sender] = 0;

        // 转移资金
        recipient.transfer(value);

        // 更新拍卖状态为已结束
        auctionState = State.Finalized;
    }

    /**
     * @dev 返回拍卖内容
     * @return 拍卖标题、起拍价、拍卖描述、拍卖状态
     */
    function returnContents()
        public
        view
        returns (
            string memory,
            uint,
            string memory,
            State
        )
    {
        return (title, startPrice, description, auctionState);
    }
}
