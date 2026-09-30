pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNft is ERC721 {
    
    constructor() ERC721("Mynfs", "MTKnfs") {

    }
    mapping (uint => address) public lot_owner;
    function approve2 (address _to,uint _nfsid)  public  {
        approve(_to, _nfsid);
        lot_owner[_nfsid] = msg.sender;
    }
    function getMyNftAddress() public view returns (address) {
        return address(this);
    }
}