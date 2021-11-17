//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./BullsToTheMoonInterface.sol";

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
contract BullsToTheMoon is ERC721Enumerable, BullsToTheMoonInterface {

    /// @notice Counter of bullId
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
        uint indexed bullId,
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
    modifier checkOwner(uint bullId) {
        require(
            _isApprovedOrOwner(_msgSender(), bullId),
            "wrong owner"
        );
        _;
    }

    /**
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function open(uint bullId) override external checkOwner(bullId) {
        Bull storage target = bullStateOf[bullId];
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
        emit BullState(bullId, target.proxy, false, currPrice, target.roi);
    }

    /**
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function close(uint bullId) override external checkOwner(bullId) {
        Bull storage target = bullStateOf[bullId];
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
        emit BullState(bullId, target.proxy, true, currPrice, target.roi);
    }

    /**
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function breed(bytes32 namehash) override external returns (uint) {
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
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function regretOpen(uint bullId) override external checkOwner(bullId) {

    }

    /**
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function regretClose(uint bullId) override external checkOwner(bullId) {
        
    }

    /**
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function occupy(uint bullId, uint fieldId) override external checkOwner(bullId) {

    }

    /**
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function vote(uint proposalId, uint fieldCount) override external {

    }

    /**
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function propose(string memory proposedBaseURI) override external {
        
    }

    /**
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function startVote() override external {

    }

    /**
     * @notice See ../BullsToTheMoonInterface.sol
     */
    function endVote() override external {

    }

    /**
     * @dev Resolve ENS-namehash to Chainlink price feed proxy
     */
    function _resolve(bytes32 node) internal view returns (address) {
        Resolver resolver = ens.resolver(node);
        return resolver.addr(node);
    }
}
