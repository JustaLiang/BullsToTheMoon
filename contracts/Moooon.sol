//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @notice ENS registry to get chainlink resolver
 */
interface ENS {
    function resolver(bytes32) external view returns (Resolver);
}

/**
 * @notice Chainlink resolver to get price feed proxy
 */
interface Resolver {
    function addr(bytes32) external view returns (address);
}

/**
 * @title Moooon: Combine to-the-moon and the moo sound from bulls (cow actually LUL)
 * @author Justa Liang
 */
contract Moooon is ERC721Enumerable {

    /// @notice Counter of tokenId
    uint public counter;

    /// @notice ENS interface (fixed address)
    ENS public ens;

    /// @dev Moooon's state
    struct MoooonState {
        address     proxy;        // which proxy of Chainlink price feed
        bool        closed;       // position closed
        int         latestPrice;  // latest updated price from Chainlink
        int         roi;          // return on investment
    }

    /// @dev Moooon's profile for viewing
    struct MoooonProfile {
        address     proxy;
        bool        closed;
        int         latestPrice;
        int         roi;
        string      uri;
    }

    /// @dev Moooon's state stored on-chain
    mapping(uint => MoooonState) public moooonState;

    /// @notice Emit when a Moooon's state changes 
    event CurrentMoooonState(
        uint indexed moooonId,
        address indexed proxy,
        bool indexed closed,
        int latestPrice,
        int roi
    );

    /**
     * @dev Set name, symbol, and addresses of interactive contracts
    */
    constructor(address ensRegistryAddr)
        ERC721("Moooon", "MOO")
    {
        counter = 0;
        ens = ENS(ensRegistryAddr);
    }

    /**
     * @notice Breed a moooon
     * @param namehash ENS-namehash of given pair (ex: eth-usd.data.eth)
     * @return ID of the new moooon
    */
    function breed(bytes32 namehash) external returns (uint) {
        address proxyAddr = _resolve(namehash);
        require(
            proxyAddr != address(0),
            "breed: invalid proxy"
        );
        // get current price
        AggregatorV3Interface pricefeed = AggregatorV3Interface(proxyAddr);
        (,int currPrice,,,) = pricefeed.latestRoundData();

        // mint moooon and store its state on chain
        uint newId = counter;
        _safeMint(msg.sender, newId);
        moooonState[newId] = MoooonState(proxyAddr, false, currPrice, 0);

        emit CurrentMoooonState(newId, proxyAddr, false, currPrice, 0);
        counter++;
        return newId;
    }

    /**
     * @dev Check the owner
    */
    modifier checkOwner(uint moooonId) {
        require(
            _isApprovedOrOwner(msg.sender, moooonId),
            "wrong owner"
        );
        _;
    }

    /**
     * @dev Resolve ENS-namehash to Chainlink price feed proxy
    */
    function _resolve(bytes32 node) internal view returns (address) {
        Resolver resolver = ens.resolver(node);
        return resolver.addr(node);
    }
}
