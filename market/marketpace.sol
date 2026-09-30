// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import ".//nft.sol";
import ".//token.sol";
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Market {
    struct Listing {
        address seller;       
        address paymentToken; 
        uint256 price;        
        bool active;
    }
    // nftContract => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => bool) public allowedPaymentTokens; 
    uint96 public feeBps = 250;   
    address public contractowner = msg.sender; 
    bool pause = false;
    //аддрес перевода комисии
    address  public feeRecipient = msg.sender;
    event ItemListed(address indexed seller, address indexed nft, uint256 indexed tokenId, address paymentToken, uint256 price);
    event ListingCanceled(address indexed seller, address indexed nft, uint256 indexed tokenId);

    modifier nftOwnerOrApproved(address _nft, uint256 _tokenId) {
        address owner = IERC721(_nft).ownerOf(_tokenId);
        require(
            msg.sender == owner || 
            IERC721(_nft).getApproved(_tokenId) == msg.sender || 
            IERC721(_nft).isApprovedForAll(owner, msg.sender), 
            "Not owner or approved"
        );
        _;
    }
    modifier onlioperator (){
        require(msg.sender == feeRecipient, "not operator");
        _;
    }
    modifier pausecheck (){
        require(pause == false, "pause");
        _;
    }

    function listItem (address _nft, uint256 _tokenId, address _paymentToken, uint256 _price) public pausecheck nftOwnerOrApproved(_nft, _tokenId) {
        require(_price > 0, "Price must be above zero");
        require(allowedPaymentTokens[_paymentToken], "Payment token not whitelisted");
        
        address owner = IERC721(_nft).ownerOf(_tokenId);
        require(
            IERC721(_nft).getApproved(_tokenId) == address(this) || 
            IERC721(_nft).isApprovedForAll(owner, address(this)),
            "Market not approved to transfer NFT"
        );

        listings[_nft][_tokenId] = Listing({
            seller: owner, 
            paymentToken: _paymentToken,
            price: _price,
            active: true
        });
        emit ItemListed(owner, _nft, _tokenId, _paymentToken, _price);
    }

    function updateListing(address _nft, uint256 _tokenId, address _paymentToken, uint256 _price) public pausecheck nftOwnerOrApproved(_nft, _tokenId) {
        // Проверяем, что объявление существует и активно перед обновлением
        require(listings[_nft][_tokenId].active, "Listing does not exist");
        require(_price > 0, "Price must be above zero");
        require(allowedPaymentTokens[_paymentToken], "Payment token not whitelisted");
        
        address owner = IERC721(_nft).ownerOf(_tokenId);
        require(
            IERC721(_nft).getApproved(_tokenId) == address(this) || 
            IERC721(_nft).isApprovedForAll(owner, address(this)),
            "Market not approved to transfer NFT"
        );
        listings[_nft][_tokenId] = Listing({
            seller: owner, 
            paymentToken: _paymentToken,
            price: _price,
            active: true
        });
        emit ItemListed(owner, _nft, _tokenId, _paymentToken, _price);
    }

    function cancelListing (address _nft, uint256 _tokenId) public pausecheck nftOwnerOrApproved(_nft, _tokenId) {
        require(listings[_nft][_tokenId].active, "Listing not active");
        address owner = IERC721(_nft).ownerOf(_tokenId);
        delete listings[_nft][_tokenId]; 

        emit ListingCanceled(owner, _nft, _tokenId);
    }
    function buyItem(address _nft, uint256 _tokenId, address _expectedToken, uint256 _expectedPrice) public pausecheck {
        // Получаем ссылку на структуру объявления (с маленькой буквы)
        Listing storage listing = listings[_nft][_tokenId];
        uint256 feeAmount = (_expectedPrice * feeBps) / 10000;
        uint256 sellerAmount = _expectedPrice - feeAmount;
        // Проверки безопасности
        require(listing.active, "Listing is not active");
        require(listing.paymentToken == _expectedToken, "Unexpected payment token");
        require(listing.price == _expectedPrice, "Price mismatch or updated");
        require(IERC20(_expectedToken).balanceOf(msg.sender) >= listing.price, "Insufficient token balance");

        listing.active = false;
        address seller = listing.seller;
        delete listings[_nft][_tokenId];
        
        require(
            IERC20(_expectedToken).transferFrom(msg.sender, seller, sellerAmount), 
            "Token transfer failed"
        );
        if (feeAmount > 0) {
            require(
                IERC20(_expectedToken).transferFrom(msg.sender, feeRecipient, feeAmount), 
                "Fee transfer failed"
            );

            IERC721(_nft).safeTransferFrom(seller, msg.sender, _tokenId);
        }
    }
    function setFee(uint96 _bps) public onlioperator {
        require(_bps <= 1000, "need low dps");
        feeBps = _bps;
    }
    function setFeeRecipient(address _feeRecipient) public onlioperator {
        feeRecipient = _feeRecipient;
    }
    function setpause () public onlioperator {
        pause = true;
    }
    function setunpause () public onlioperator {
        pause = false;
    }
    
}
