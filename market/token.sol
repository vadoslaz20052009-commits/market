pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit {
    int public constant cinys = 18;
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {

    }
    function getMyTOkenAddress() public view returns (address) {
        return address(this);
    }
}