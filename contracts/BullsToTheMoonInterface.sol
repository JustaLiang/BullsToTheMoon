//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title Bulls (dynamic NFTs) that grow with rising price
 * @author Justa Liang
 */
interface BullsToTheMoonInterface {

    /**
     * @notice Breed a bull
     * @param namehash ENS-namehash of given pair (ex: eth-usd.data.eth => 0xf599f4cd075a34b92169cf57271da65a7a936c35e3f31e854447fbb3e7eb736d) 
     * @return ID of the new bull
     */
    function breed(bytes32 namehash) external returns (uint);

    /**
     * @notice Open a long position and update latest price of certain bull
     * @param bullId ID of the bull
     */
    function open(uint bullId) external;

    /**
     * @notice Close the position and compute ROI of certain bull
     * @param bullId ID of the bull
     */
    function close(uint bullId) external;

    /**
     * @notice Regret opening position when price drop after
     * @param bullId ID of the bull
     */
    function regretOpen(uint bullId) external;

    /**
     * @notice Regret closing position when price rise after
     * @param bullId ID of the bull
     */
    function regretClose(uint bullId) external;

    /**
     * @notice Occupy certain field with certain bull to earn GrassForBulls (ERC20-token)
     * @param bullId ID of the bull
     * @param fieldId ID of the field on grassland
     */
    function occupy(uint bullId, uint fieldId) external;

    /**
     * @notice Propose the next-generation skin
     * @param proposedBaseURI Base URI of proposer's designed NFTs
     */
    function propose(string memory proposedBaseURI) external;

    /**
     * @notice Start the vote
     */
    function startVote() external;

    /**
     * @notice Vote the proposals using owned field
     * @param proposalId ID of the proposal
     * @param fieldCount Number of owned field
     */
    function vote(uint proposalId, uint fieldCount) external;

    /**
     * @notice End the vote
     */
    function endVote() external;
}