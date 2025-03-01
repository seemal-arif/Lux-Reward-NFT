// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
/**
 * @title LuxRewardNFT
 * @dev ERC721A contract for Web3 Game NFTs with Reward Cards, Loot Boxes, and Surprise NFTs.
 */
contract LuxRewardNFT is ERC721A, Ownable, ReentrancyGuard ,ERC2981{

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    IERC20 public immutable tlnToken;
    
    address public moderator;                   // @notice Address used to sign Web2 mint authorizations
    string public contractURI;                  // @notice Base contract metadata URI (e.g., for OpenSea)
    uint256 public royaltyFee;                  // Royalty fee percentage (e.g., 500 = 5%)
    address public royaltyRecipient;            // Address to receive royalty payments

    mapping(uint256 tokenId => string tokenURI) private _tokenURIs;
    mapping(address walletAddress => uint256 nonceNumber ) public nonces; // Track nonces for each user
    
    event ContractURIUpdated(string newContractURI);
    event moderatorUpdated(address indexed newWallet);
    event RoyaltyUpdated(uint256 newFee, address newRecipient);
    event FundsWithdrawn(address indexed withdrawer, uint256 amount);
    
    /**
     * @param name NFT name
     * @param symbol NFT symbol
     * @param tlnTokenContract Address of TLN ERC20 token
     * @param owner Address of owner wallet to receive payments
     * @param _moderator Address for backend signature verification
     */
    constructor(
        string memory name,
        string memory symbol,
        address tlnTokenContract,
        address owner,
        address _moderator,
        address _royaltyReceiver,
        uint96 _royaltyFee
    ) ERC721A(name, symbol) Ownable(owner) {

        require(tlnTokenContract != address(0), "Invalid TLN token address");
        require(_moderator != address(0), "Invalid signer address");
        require(owner != address(0), "Invalid owner address");
        require(_royaltyReceiver != address(0), "Invalid royalty receiver");

        tlnToken = IERC20(tlnTokenContract);
        moderator = _moderator;

        royaltyFee = _royaltyFee;
        royaltyRecipient = _royaltyReceiver;
        // Set default royalty (500bps = 5%)
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFee);
    }


    function isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool isValid) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == moderator;
    }

    // Set tokenURI(Metadata URI) against NFTId 
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "Token does not exist");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @notice Mint Reward Cards using Web2 coins (backend signature validation).
     * @param quantity Number of NFTs to mint
     * @param uris Array of custom URIs for minted NFTs
     * @param signature Signature signed by moderator
     */
    function mintRewardWeb2(
        uint256 quantity,
        string[] calldata uris,
        bytes memory signature
    ) external nonReentrant {
        require(quantity == uris.length, "Mismatch between quantity and URIs");  

        uint256 userNonce = nonces[msg.sender];
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, quantity, userNonce));
        require(isValidSignature(msgHash, signature), "Invalid signature");
        nonces[msg.sender]++;

        uint256 currentId = totalSupply();
        _safeMint(msg.sender, quantity);
        for (uint256 i = 0; i < quantity; i++) {
            _setTokenURI(currentId + i, uris[i]);
        }
    }

    /**
     * @notice Mint Reward Cards using TLN tokens.
     * @param quantity Number of NFTs to mint
     * @param uris Array of custom URIs
     * @param price Price per NFT in TLN tokens
     * @param signature Signature signed by moderator
     */
    function mintRewardTLN(
        uint256 quantity,
        string[] calldata uris,
        uint256 price,
        bytes memory signature
    ) external nonReentrant {

        require(quantity == uris.length, "Mismatch between quantity and URIs");
        require(price > 0, "Price cannot be zero");
        require(tlnToken.balanceOf(msg.sender) >= price, "Insufficient TLN tokens");

        uint256 userNonce = nonces[msg.sender];
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, quantity, price, userNonce));
        require(isValidSignature(msgHash, signature), "Invalid signature");
        nonces[msg.sender]++;

        tlnToken.safeTransferFrom(msg.sender, address(this), price);

        uint256 currentId = totalSupply();
        _safeMint(msg.sender, quantity);

        for (uint256 i = 0; i < quantity; i++) {
            _setTokenURI(currentId + i, uris[i]);
        }
    }

    //  Override supportsInterface to include ERC2981 support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //  Only current owner can update moderator wallet
    function updateModerator(address newModerator) external onlyOwner {
        require(newModerator != address(0), "Invalid signer address");
        moderator = newModerator;
        emit moderatorUpdated(newModerator);
    }

    // Allow the owner to update the royalty receiver and fee
    function updateRoyalty(address newReceiver, uint96 newFee) external onlyOwner {
        require(newReceiver != address(0), "Invalid receiver address");
        _setDefaultRoyalty(newReceiver, newFee);
        royaltyFee = newFee;
        royaltyRecipient = newReceiver;
        emit RoyaltyUpdated(newFee, newReceiver);
    }

    // Set contract-level metadata URI.
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
        emit ContractURIUpdated(_contractURI);
    }

    // Always withdraw available balance of TLN token in owners wallet
    function withdrawTLN() external onlyOwner {
        uint256 balance = tlnToken.balanceOf(address(this));
        address recipient = owner();
        require(balance > 0, "No TLN tokens to withdraw");

        tlnToken.safeTransfer(recipient, balance);
        emit FundsWithdrawn(msg.sender, balance);
    }

    // Get Token URI 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        string memory _uri = _tokenURIs[tokenId];
        return string(abi.encodePacked(_uri));  
    }
}





