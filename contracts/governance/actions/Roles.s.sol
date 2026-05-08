// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
import { console2 } from "forge-std/console2.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { ActionHelpers } from "./ActionHelpers.s.sol";

// This script contains a set of modular interactions with the primary layer. They  can be used for testing or setting up up an organisation after deployment. 

contract Roles is ActionHelpers {
    uint16[] mandateSlots; 
    uint256[] actionIds; 

    uint256 roleCount; 
    uint256 againstVote; 
    uint256 forVote; 
    uint256 abstainVote;

    ///////////////////////////////////////////////////////////////
    //                  PRIMARY LAYER ROLES                      // 
    ///////////////////////////////////////////////////////////////
    function getParticipantRole_PrimaryLayer(address primaryLayer, address ideasLayer, address convergenceLayer, uint256 nonce) public {
   
    }

    function revokeParticipantRole_PrimaryLayer(address primaryLayer, address ideasLayer, address convergenceLayer, uint256 nonce) public {
   
    }

    function getStewardsRole_PrimaryLayer(address primaryLayer, address ideasLayer, address convergenceLayer, uint256 nonce) public {
   
    }

    function revokeStewardsRole_PrimaryLayer(address primaryLayer, address ideasLayer, address convergenceLayer, uint256 nonce) public {
   
    }

    ///////////////////////////////////////////////////////////////
    //                  DIGITAL LAYER ROLES                      // 
    ///////////////////////////////////////////////////////////////
    function getWriterRole_DigitalLayer(address powers, uint256 nonce) public { 

    }

    function revokeWriterRole_DigitalLayer(address powers, uint256 nonce) public { 

    }

    function getMaintainerRole_DigitalLayer(address powers, uint256 nonce) public { 

    }

    function revokeMaintainerRole_DigitalLayer(address powers, uint256 nonce) public { 

    }


    ///////////////////////////////////////////////////////////////
    //                   IDEAS LAYER ROLES                       // 
    ///////////////////////////////////////////////////////////////
    function getParticipantRole_IdeasLayer(address powers, uint256 nonce) public { 

    }

    function revokeParticipantRole_IdeasLayer(address powers, uint256 nonce) public { 

    }

    function getAssessorsRole_IdeasLayer(address powers, uint256 nonce) public { 

    }

    function revokeAssessorsRole_IdeasLayer(address powers, uint256 nonce) public { 

    }

    ///////////////////////////////////////////////////////////////
    //                CONVERGENCE LAYER ROLES                    // 
    ///////////////////////////////////////////////////////////////
    function getAttendeeRole_ConvergenceLayer(address powers, uint256 nonce) public { 

    }

    function revokeAttendeeRole_ConvergenceLayer(address powers, uint256 nonce) public { 

    }

    function getStewardRole_ConvergenceLayer(address powers, uint256 nonce) public { 

    }

    function revokeStewardRole_ConvergenceLayer(address powers, uint256 nonce) public { 

    }

    function getLegalInterfacerRole_ConvergenceLayer(address powers, uint256 nonce) public { 

    }

    function revokeLegalInterfacerRole_ConvergenceLayer(address powers, uint256 nonce) public { 

    }
}
