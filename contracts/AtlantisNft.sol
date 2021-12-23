pragma solidity 0.8.7;

contract AtlantisNft {
    //--------------------------------------------------------------------------
    // STATE
    //--------------------------------------------------------------------------
    // Token name
    string private name_;
    // Token symbol
    string private symbol_;
    // Counter for unique IDs (shared across types)
    uint256 private tokenIdCounter_;
    // Data for each token type
    struct TokenType {
        // Identifier of type
        bytes32 typeId;
        // Owner of the type
        address typeOwner;
        // If this type requires permissions to mint
        bool permissionMinting;
        // If permissioned, who is able to mint
        mapping(address => bool) allowedMinters;
    }
    // Token IDs to the tokens information
    mapping(bytes32 => TokenType) private tokenTypes_;
    // Data for each token
    struct Token {
        // The type of token it is
        bytes32 typeId;
        // Address of the owner
        address owner;
        // Token approvals | Owner => Spender => Is spender
        mapping(address => mapping(address => bool)) approvedSpenders;
    }
    // Token ID to owner address
    mapping(uint256 => Token) private tokens_;
    // Owners to token count for each type. 0x0 type is balance total
    // Owner => Type => Balance
    mapping(address => mapping(bytes32 => uint256)) private balances_;
    // Owner to operator approvals | Owner => Operator => Is spender
    mapping(address => mapping(address => bool)) private operatorApprovals_;

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    /**
     * @param   _name Name for multiple token contract.
     * @param   _symbol Symbol for multiple token contract.
     * @notice  When displayed on sites that do not support this token standard
     *          the name and symbol passed in here will be used for all tokens,
     *          irrespective of token type.
     */
    constructor(string memory _name, string memory _symbol) {
        name_ = _name;
        symbol_ = _symbol;
    }

    //--------------------------------------------------------------------------
    // VIEW & PURE FUNCTIONS
    //--------------------------------------------------------------------------

    /**
     * @param   _owner Address of the owner.
     * @return  uint256 How many tokens of all types the owner has.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        return balances_[_owner][bytes32(0)];
    }

    /**
     * @param   _owner Address of the owner.
     * @param   _type The type of token.
     * @return  uint256 How many tokens the owner has of the specified token
     *          type.
     */
    function balanceOfType(address _owner, bytes32 _type)
        external
        view
        returns (uint256)
    {
        return balances_[_owner][_type];
    }

    /**
     * @param   _tokenId ID of the token.
     * @param   _owner Address of owner.
     * @param   _spender Address of the spender.
     * @return  bool If spender has been approved for specific token.
     */
    function isApproved(
        uint256 _tokenId,
        address _owner,
        address _spender
    ) external view returns (bool) {
        return tokens_[_tokenId].approvedSpenders[_owner][_spender];
    }

    // function isApprovedForAll(
    //     address _owner, 
    //     address operator 
    // )

    function approve(
        uint256 _tokenId,
        address _spender,
        bool _isApproved
    ) external {
        // Don't need to check is sender is owner as the mapping is against sender
        tokens_[_tokenId].approvedSpenders[msg.sender][_spender] = _isApproved;
    }

    function mint(bytes32 _typeId, address _to) external {
        require(
            tokenTypes_[_typeId].typeOwner != address(0),
            "Token: Type not mintable"
        );
        require(_to != address(0), "Token: mint to the zero address");
        require(_typeId != bytes32(0), "Token: cannot mint without type");

        if (tokenTypes_[_typeId].permissionMinting) {
            require(
                tokenTypes_[_typeId].typeOwner == msg.sender ||
                    tokenTypes_[_typeId].allowedMinters[msg.sender],
                "Token: Invalid minter"
            );
        }

        tokenIdCounter_ += 1;

        balances_[_to][bytes32(0)] += 1;
        balances_[_to][_typeId] += 1;

        tokens_[tokenIdCounter_].typeId = _typeId;
        tokens_[tokenIdCounter_].owner = _to;

        // emit Transfer(address(0), _to, tokenIdCounter_);
        // TODO events
    }

    function burn(bytes32 _typeId, uint256 _tokenId) external {
        require(
            tokens_[_tokenId].owner == msg.sender,
            "Token: Sender not owner"
        );
        require(_typeId != bytes32(0), "Token: cannot burn without type");

        balances_[msg.sender][bytes32(0)] -= 1;
        balances_[msg.sender][_typeId] -= 1;

        tokens_[_tokenId].typeId = bytes32(0);
        tokens_[_tokenId].owner = address(0);
    }

    function transfer(uint256 _tokenId, address _to) external {
        require(
            tokens_[_tokenId].owner == msg.sender,
            "Token: Sender not owner"
        );

        _transfer(tokens_[_tokenId].typeId, _tokenId, _to, msg.sender);
    }

    function transferFrom(
        uint256 _tokenId,
        address _from,
        address _to
    ) external {
        require(
            tokens_[_tokenId].owner == _from,
            "Token: from not token owner"
        );
        require(
            _from == msg.sender ||
                tokens_[_tokenId].approvedSpenders[_from][msg.sender],
            "Token: Not approved spender"
        );

        _transfer(tokens_[_tokenId].typeId, _tokenId, _to, _from);
    }

    function createTokenType(
        bytes32 _typeId,
        bool _permissionMinting,
        address[] calldata _minters
    ) external {
        require(
            tokenTypes_[_typeId].typeOwner == address(0),
            "Token: Type already exists"
        );

        tokenTypes_[_typeId].typeId = _typeId;
        tokenTypes_[_typeId].typeOwner = msg.sender;

        if (_permissionMinting && _minters.length != 0) {
            tokenTypes_[_typeId].permissionMinting = _permissionMinting;

            for (uint256 i = 0; i < _minters.length; i++) {
                tokenTypes_[_typeId].allowedMinters[_minters[i]] = true;
            }
        }
    }

    function updateMinters(
        bytes32 _typeId,
        address[] calldata _minters,
        bool[] calldata _isMinter
    ) external {
        require(
            tokenTypes_[_typeId].typeOwner == msg.sender,
            "Token: Owner can change minter"
        );
        require(_minters.length == _isMinter.length, "Token: Array mismatch");

        for (uint256 i = 0; i < _minters.length; i++) {
            tokenTypes_[_typeId].allowedMinters[_minters[i]] = _isMinter[i];
        }
    }

    function transferTypeOwnership(bytes32 _typeId, address _newOwner)
        external
    {
        require(
            tokenTypes_[_typeId].typeOwner == msg.sender,
            "Token: Owner can change minter"
        );

        tokenTypes_[_typeId].typeOwner = _newOwner;
    }

    function _transfer(
        bytes32 _typeId,
        uint256 _tokenId,
        address _to,
        address _from
    ) internal {
        balances_[_from][bytes32(0)] -= 1;
        balances_[_from][_typeId] -= 1;
        tokens_[_tokenId].owner = _to;

        balances_[_to][bytes32(0)] += 1;
        balances_[_to][_typeId] += 1;
    }
}
