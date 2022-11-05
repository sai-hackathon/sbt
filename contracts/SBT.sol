// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = address(msg.sender);
        emit OwnershipTransferred(address(0), address(msg.sender));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == address(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "Not minted");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "Not minted");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @title ERC721 Soulbound Token
/// @author 0xArbiter
/// @author Andreas Bigger <https://github.com/abigger87>
/// @dev ERC721 Token that can be burned and minted but not transferred.
abstract contract Soulbound is ERC721 {

    // Custom SBT error for if users try to transfer
    error TokenIsSoulbound();

    /// @dev Put your NFT's name and symbol here
    constructor(string memory name, string memory symbol) ERC721(name, symbol){}

    /// @notice Prevent Non-soulbound transfers
    function onlySoulbound(address from, address to) internal pure {
        // Revert if transfers are not from the 0 address and not to the 0 address
        if (from != address(0) && to != address(0)) {
            revert TokenIsSoulbound();
        }
    }

    /// @notice Override token transfers to prevent sending tokens
    function transferFrom(address from, address to, uint256 id) public override {
        onlySoulbound(from, to);
        super.transferFrom(from, to, id);
    }
}
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: modulo by zero");
    return a % b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {trySub}.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryDiv}.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting with custom message when dividing by zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryMod}.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

contract SBT is Soulbound, Ownable {

    using SafeMath for uint256;

    struct Skill {
        string skillName;
    }

    struct Deviation {
        uint16 average;
        uint16 standardDeviation;
    }

    Skill[] private _skills;
    mapping(uint256 => string) _ooccupations; // sbt_id -> occupation code
    mapping(uint256 => mapping(uint => Deviation)) private _deviations;  // sender_sbt_id -> skill_id -> 評価偏差
    mapping(uint256 => mapping(uint => uint8[])) private _points;  // sender_sbt_id -> skill_id -> 評価履歴
    mapping(uint256 => mapping(uint => uint8[])) private _assessments; // receiver_sbt_id -> skill_id -> 評価一覧
    mapping(uint256 => mapping(uint => uint8)) private _scores; // sbt_id -> skill_id -> 数値

    string private _baseURI;
    uint256 private _totalSupply;

    uint256[] private evaluationPoints;
    mapping(uint256 => mapping(address => bool)) private usedEvaluationPoints;

    constructor(string memory _newBaseURI) Soulbound("SBT", "SBT")
    {
        _baseURI = _newBaseURI;
        _skills.push(Skill({skillName: "Knowledge"}));
        _skills.push(Skill({skillName: "Skill"}));
        _skills.push(Skill({skillName: "Ability"}));
        _skills.push(Skill({skillName: "Interest"}));
    }

    function mint(address _to, string memory _ooccupation) external
    {
        require(balanceOf(_to) == 0, "Already exists");
        _mint(_to, _totalSupply);
        _ooccupations[_totalSupply] = _ooccupation;
        _totalSupply = _totalSupply + 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        return string(abi.encodePacked(_baseURI, toString(_tokenId)));
    }

    function toString(uint256 _value) internal pure returns (string memory)
    {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            unchecked {
                digits++;
                temp /= 10;
            }
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            unchecked {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
                _value /= 10;
            }
        }
        return string(buffer);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner
    {
        _baseURI = _newBaseURI;
    }

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }
    function skill(uint256 _skillId) public view returns (Skill memory)
    {
        return _skills[_skillId];
    }
    function skillLength() public view returns (uint256)
    {
        return _skills.length;
    }

    function evaluate(uint256 _senderSbtId, uint256 _receiverSbtId, uint8[] memory _addPoints) external onlyOwner
    {
        require(_addPoints.length == 4, "invalid length");

        for(uint i = 0; i < 4; i++) {

            uint8 _point = _addPoints[i];
            require(_point > 0 && _point <= 10, "Out of point");
            require(ownerOf(_senderSbtId) == address(msg.sender), "Not owner");
            require(ownerOf(_receiverSbtId) != address(0), "Not minted");

            Deviation memory _deviation = _deviations[_senderSbtId][i];

            // update assessment

            if(_deviation.average > _point) {
                uint256 base = uint256(_deviation.average).sub(_point).mul(10).div(_deviation.standardDeviation);
                _assessments[_receiverSbtId][i].push(uint8(uint256(50).sub(base)));
            } else {
                uint256 base = uint256(_point).sub(_deviation.average).mul(10).div(_deviation.standardDeviation);
                _assessments[_receiverSbtId][i].push(uint8(uint256(50).add(base)));
            }

            // update deviation

            uint256 sum = _points[_senderSbtId][i].length.mul(_deviation.average);
            _points[_senderSbtId][i].push(_point);
            sum += _point;
        
            uint16 average = uint16(sum.div(_points[_senderSbtId][i].length));
            uint256 baseStandardDeviation = 0;

            for(uint256 j = 0; j < _points[_senderSbtId][i].length; j++) {
                if(_points[_senderSbtId][i][j] > average) {
                    baseStandardDeviation += (_points[_senderSbtId][i][j] - average) * (_points[_senderSbtId][i][j] - average);
                } else {
                    baseStandardDeviation += (average - _points[_senderSbtId][i][j]) * (average - _points[_senderSbtId][i][j]);
                }
            }

            _deviations[_senderSbtId][i].average = average;
            _deviations[_senderSbtId][i].standardDeviation = uint16(sqrt(baseStandardDeviation.div(_points[_senderSbtId][i].length)));
        }
    }

    function assessment(uint256 _sbtId, uint _skillId) external view returns (uint256)
    {

        if(_assessments[_sbtId][_skillId].length == 0) {
            return 50;
        }

        uint256 sum = 0;
        for(uint8 i; i < _assessments[_sbtId][_skillId].length; i++) {
            sum += _assessments[_sbtId][_skillId][i];
        }
        
        return sum.div(_assessments[_sbtId][_skillId].length);
    }

    function setScore(uint256 _sbtId, uint8[] memory _addScores) external onlyOwner
    {
        for(uint i = 0; i < 4; i++) {
            uint8 _score = _addScores[i];
            _scores[_sbtId][i] = _score;
        }
    }

    function score(uint256 _sbtId, uint _skillId) external view returns (uint8)
    {
        return _scores[_sbtId][_skillId];
    }

    function occupation(uint256 _sbtId) external view returns (string memory)
    {
        return _ooccupations[_sbtId];
    }
    function setOccupation(uint256 _sbtId, string memory _ooccupation) external
    {
        require(ownerOf(_sbtId) == address(msg.sender), "Not owner");
        _ooccupations[_sbtId] = _ooccupation;
    }

    function sqrt(uint256 x) internal pure returns(uint256)
    {
        uint256 z = x.add(1).div(2);
        uint256 y = x;
        while(z < y){
        y = z;
        z = x.div(z).add(z).div(2);
        }
        return y;
    }

}
