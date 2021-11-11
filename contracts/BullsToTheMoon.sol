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
 * @title Bulls (dynamic NFTs) that grow with rising price
 * @author Justa Liang
 */
contract BullsToTheMoon is ERC721Enumerable {

    /// @notice Counter of tokenId
    uint public counter;

    /// @notice ENS interface (fixed address)
    ENS public ens;

    /// @dev Bull's state
    struct Bull {
        address     proxy;        // which proxy of Chainlink price feed
        bool        closed;       // position closed
        int         latestPrice;  // latest updated price from Chainlink
        int         roi;          // return on investment
    }

    /// @dev Bull's profile for viewing
    struct BullProfile {
        address     proxy;
        bool        closed;
        int         latestPrice;
        int         roi;
        string      uri;
    }

    /// @dev Bull's state stored on-chain
    mapping(uint => Bull) public bullStateOf;

    /// @notice Emit when a bull's state changes 
    event BullState(
        uint indexed tokenId,
        address indexed proxy,
        bool indexed closed,
        int latestPrice,
        int roi
    );

    /**
     * @dev Set name, symbol, and addresses of interactive contracts
     */
    constructor(address ensRegistryAddr)
        ERC721("BullsToTheMoon", "B2M")
    {
        counter = 0;
        ens = ENS(ensRegistryAddr);
    }

    /**
     * @dev Check the owner
     */
    modifier checkOwner(uint tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "wrong owner"
        );
        _;
    }

    /**
     * @notice Open a long position and update latest price of certain bull
     * @param tokenId ID of the bull
     */
    function open(uint tokenId) external checkOwner(tokenId) {
        Bull storage target = bullStateOf[tokenId];
        require(
            target.closed,
            "bull already opened"
        );

        // get current price
        AggregatorV3Interface pricefeed = AggregatorV3Interface(target.proxy);
        (,int currPrice,,,) = pricefeed.latestRoundData();

        // update on-chain data
        target.latestPrice = currPrice;
        target.closed = false;

        // emit bull state
        emit BullState(tokenId, target.proxy, false, currPrice, target.roi);
    }

    /**
     * @notice Close the position and compute ROI of certain bull
     * @param tokenId ID of the bull
     */
    function close(uint tokenId) external checkOwner(tokenId) {
        Bull storage target = bullStateOf[tokenId];
        require(
            !target.closed,
            "bull already closed"
        );

        // get current price
        AggregatorV3Interface pricefeed = AggregatorV3Interface(target.proxy);
        (,int currPrice,,,) = pricefeed.latestRoundData();

        // update on-chain data
        target.roi = currPrice*(10000+target.roi)/target.latestPrice-10000;
        target.closed = true;

        // emit bull state
        emit BullState(tokenId, target.proxy, true, currPrice, target.roi);
    }

    /**
     * @notice Breed a bull
     * @param namehash ENS-namehash of given pair (ex: eth-usd.data.eth)
     * @return ID of the new bull
     */
    function breed(bytes32 namehash) external returns (uint) {
        address proxyAddr = _resolve(namehash);
        require(
            proxyAddr != address(0),
            "invalid proxy"
        );
        // get current price
        AggregatorV3Interface pricefeed = AggregatorV3Interface(proxyAddr);
        (,int currPrice,,,) = pricefeed.latestRoundData();

        // mint bull and store its state on chain
        uint newId = counter;
        _safeMint(_msgSender(), newId);
        bullStateOf[newId] = Bull(proxyAddr, false, currPrice, 0);

        emit BullState(newId, proxyAddr, false, currPrice, 0);
        counter++;
        return newId;
    }
    
    /**
     * @dev Resolve ENS-namehash to Chainlink price feed proxy
     */
    function _resolve(bytes32 node) internal view returns (address) {
        Resolver resolver = ens.resolver(node);
        return resolver.addr(node);
    }
}
