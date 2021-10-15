// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @author  @vonie610 (Twitter & Telegram) | @Nicca42 (GitHub)
 * @dev     Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721]
 *          Non-Fungible Token Standard, including the Metadata extension, but
 *          not including the Enumerable extension, which is available
 *          separately as {ERC721Enumerable}.
 * @notice  This contract was pulled out of the openzeppelin contract library
 *          and modified to allow for multiple token types to exist on one
 *          contract. This is required for treasure maps and coordinates to be
 *          retrieved and executed as gas effetely as possible.
 */
contract ModifiedErc721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private name_;

    // Token symbol
    string private symbol_;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners_;

    // Mapping of token ID to token type
    mapping(uint256 => bytes32) private tokenType_;
    // FUTURE could make mapping for all types allowing for permission-ed
    // minting of tokens, type creations and ownership.

    // Mapping of owners to token type to balance. 0 type is balance total.
    mapping(address => mapping(bytes32 => uint256)) private balances_;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals_;

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

    //--------------------------------------------------------------------------
    // EDITED
    //--------------------------------------------------------------------------
    // The below code is modified and added code in order to facilitate having
    // typed tokens.
    //
    // When minting tokens you now need to specify the token type. A view
    // function was also added for getting a tokens type.
    //
    // Additional notes:
    // A lot more grace can go into the way this is done, i.e
    // being able to approve an address as a spender of all your tokens of the
    // same price.
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // FUTURE IMPROVEMENTS (possibly make this an EIP?)
    //--------------------------------------------------------------------------
    // This contract can be significantly improved via the creation of the 
    // following public functions:
    // - `createTokenType(bytes32 _type, bool _publiclyMintable, bool _isBurnable)`
        // This function allows callers to add unique token types. Marking a 
        // token as not burnable will block burning and transfering to the 0x0
        // address. Making a type publicly mintable means that anyone can mint
        // a token of that type. If the token is not publicly mintable the
        // minter role can be controlled through:
        // - `addMinterForType(address _minter, bool _canMint)`
        // - `addMintControllerForType(address _controller, bool _canAddMinters)`
    // - `mint(bytes32 _type, address _to)`
        // Mints a new token (restricted by the token type and minter roles)
        // Enforces unique token IDs, keeps a count for total circulating supply
        // of each token type. 
    // - `burn(uint256 _tokenID)`
        // Allows for the burning of a token. If burning for the token type is
        // disabled this function will revert. 
    //--------------------------------------------------------------------------

    /**
     * @param   _owner Address of the owner.
     * @param   _type The type of token.
     * @return  uint256 How many tokens the owner has of the specified token 
     *          type.
     */
    function balanceOfType(address _owner, bytes32 _type)
        public
        view
        returns (uint256)
    {
        return balances_[_owner][_type];
    }

    /**
     * @param   _tokenID The ID of the token. 
     * @return  bytes32 The identifier for the token type.
     */
    function getTokenType(uint256 _tokenID) public view returns (bytes32) {
        return tokenType_[_tokenID];
    }

    /**
     * @param   _type The type of token being minted.
     * @param   _to The receiving address for the newly minted token.
     * @param   _tokenId The ID for the token. 
     * @dev     Safely mints `tokenId` and transfers it to `to`. If `to` refers 
     *          to a smart contract, it must implement 
     *          {IERC721Receiver-onERC721Received}, which is called upon a safe 
     *          transfer.
     */
    function _safeMint(
        bytes32 _type,
        address _to,
        uint256 _tokenId
    ) internal virtual {
        _safeMint(_type, _to, _tokenId, "");
    }

    /**
     * @param   _type The type of token being minted.
     * @param   _to The receiving address for the newly minted token.
     * @param   _tokenId The ID for the token.
     * @dev     Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], 
     *          with an additional `data` parameter which is forwarded in 
     *          {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        bytes32 _type,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(_type, _to, _tokenId);
        require(
            _checkOnERC721Received(address(0), _to, _tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @param   _type The type of token being minted.
     * @param   _to The receiving address for the newly minted token.
     * @param   _tokenId The ID for the token.
     */
    function _mint(
        bytes32 _type,
        address _to,
        uint256 _tokenId
    ) internal virtual {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(_type != bytes32(0), "ERC721: cannot mint without type");
        require(!_exists(_tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), _to, _tokenId);

        balances_[_to][bytes32(0)] += 1;
        balances_[_to][_type] += 1;
        tokenType_[_tokenId] = _type;
        owners_[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }

    /**
     * @param   _tokenId ID of the token to be destroyed. 
     */
    function _burn(uint256 _tokenId) internal virtual {
        address owner = this.ownerOf(_tokenId);

        _beforeTokenTransfer(owner, address(0), _tokenId);

        // Clear approvals
        _approve(address(0), _tokenId);

        bytes32 tokenType = tokenType_[_tokenId];

        balances_[owner][bytes32(0)] -= 1;
        balances_[owner][tokenType] -= 1;
        delete owners_[_tokenId];
        delete tokenType_[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
    }

    //--------------------------------------------------------------------------
    // UNEDITED OPENZEPPELIN CODE
    //--------------------------------------------------------------------------
    // Below is the mostly unchanged openzeppelin code for ERC721 
    // implementation. The only difference is how the mapping `balances_` is 
    // used and accessed, as it is now a 2D mapping.
    //--------------------------------------------------------------------------

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        
        return balances_[owner][bytes32(0)];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = owners_[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return name_;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = this.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return tokenApprovals_[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        operatorApprovals_[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return operatorApprovals_[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return owners_[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = this.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            this.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        bytes32 tokenType = tokenType_[tokenId];

        balances_[from][tokenType] -= 1;
        balances_[from][bytes32(0)] -= 1;
        balances_[to][tokenType] += 1;
        balances_[to][bytes32(0)] += 1;
        owners_[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        tokenApprovals_[tokenId] = to;
        emit Approval(this.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
