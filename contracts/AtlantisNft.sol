pragma solidity 0.8.7;

contract AtlantisNft {
    // Token name
    string private name_;

    // Token symbol
    string private symbol_;

    struct TokenType {
        bytes32 typeId;
        address typeOwner;
        bool permissionMinting;
        mapping(address => bool) allowedMinters;
    }

    // Token IDs to the tokens information
    mapping(bytes32 => TokenType) private tokenTypes_;

    struct Token {
        bytes32 typeId;
        address owner;
        // Owner        => Spender         => Is spender
        mapping(address => mapping(address => bool)) approvedSpenders;
    }

    // Mapping from token ID to owner address
    mapping(uint256 => Token) private tokens_;

    // Mapping of owners to token type to balance. 0 type is balance total.
    // Owner        => Type            => Balance
    mapping(address => mapping(bytes32 => uint256)) private balances_;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals_;

    /**
     * @param   _name Name for token.
     * @param   _symbol Symbol for token.
     */
    constructor(string memory _name, string memory _symbol) {
        name_ = _name;
        symbol_ = _symbol;
    }

    function createTokenType(
        bytes32 _tokenId, 
        bool _permissionMinting, 
        address[] calldata _minters
    ) external {
        require(
            tokenTypes_[_tokenId].typeOwner == address(0),
            "Token: Type already exists"
        );

        tokenTypes_[_tokenId].typeId = _tokenId;
        tokenTypes_[_tokenId].typeOwner = msg.sender;

        if(_permissionMinting && _minters.length != 0) {
            for (uint256 i = 0; i < _minters.length; i++) {
                tokenTypes_[_tokenId].allowedMinters[_minters[i]] = true;
            }
        }
    }

    function updateMinters(
        bytes32 _tokenId,
        address[] calldata _minters, 
        bool[] calldata _isMinter
    ) external {
        require(
            tokenTypes_[_tokenId].typeOwner == msg.sender,
            "Token: Owner can change minter"
        );
        require(
            _minters.length == _isMinter.length,
            "Token: Array mismatch"
        );

        for (uint256 i = 0; i < _minters.length; i++) {
            tokenTypes_[_tokenId].allowedMinters[_minters[i]] = _isMinter[i];
        }
    }

    function transferTypeOwnership(bytes32 _tokenId, address _newOwner) external {
        require(
            tokenTypes_[_tokenId].typeOwner == msg.sender,
            "Token: Owner can change minter"
        );

        tokenTypes_[_tokenId].typeOwner = _newOwner;
    }
}