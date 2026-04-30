// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { console2 } from "forge-std/console2.sol";
import { DeploySetup } from "./DeploySetup.s.sol";
import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { Governed721 } from "@lib/powers-monorepo/solidity/src/helpers/Governed721.sol";
import { Nominees } from "@lib/powers-monorepo/solidity/src/helpers/Nominees.sol";
import { ZKPassportHelper } from "@lib/circuits/src/solidity/src/ZKPassportHelper.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol";
import { PowersDeployer } from "@lib/powers-monorepo/solidity/src/helpers/PowersDeployer.sol";

contract PhysicalLayer is DeploySetup {
    PowersTypes.Conditions conditions;
    PowersTypes.Flow[] flows;

    PowersTypes.MandateInitData[] constitution; 
    PowersFactory powersFactory;

    uint16 public assignRepsMandateId;

    //////////////////////////////////////////////////////////////////////
    //                        INITIALISATION                            //
    //////////////////////////////////////////////////////////////////////
    function run() external { 
        // Deploy factories first (empty) so their addresses are available
        console2.log("Deploying Physical Layer factory (contract only)...");
        vm.startBroadcast();
        PowersDeployer PhysicalLayerDeployer = new PowersDeployer();  // £todo: I think this can be deployed as a singleton contract
        powersFactory = new PowersFactory(
            "Physical Layer", // name
            string.concat(baseURI, "physicalLayer.json"), // uri
            helperConfig.getMaxCallDataLength(block.chainid), // max call data length
            helperConfig.getMaxReturnDataLength(block.chainid), // max return data length
            helperConfig.getMaxExecutionsLength(block.chainid), // max executions length 
            address(PhysicalLayerDeployer)
        );
        vm.stopBroadcast(); 
        console2.log("Physical Layer factory deployed at:", address(powersFactory));
    }

    //////////////////////////////////////////////////////////////////////
    //                          CONSTITUTE                              //
    //////////////////////////////////////////////////////////////////////
    function constitutePowers(
        address primaryLayer,
        address governed721,
        address activityToken,
        address nominees,
        uint16 mintPoapTokenId,
        uint16 requestAllowancePhysicalLayerId
    ) public {
        _createConstitution(primaryLayer, governed721, activityToken, nominees, mintPoapTokenId, requestAllowancePhysicalLayerId);
        
        PowersTypes.MandateInitData[] memory constitutionPacked = packageInitData(constitution, PACKAGE_SIZE, 1);
        vm.startBroadcast();
        powersFactory.addMandates(constitutionPacked);
        powersFactory.addFlows(flows);
        powersFactory.transferOwnership(primaryLayer);
        vm.stopBroadcast();
    }

    //////////////////////////////////////////////////////////////////////
    //                            GETTERS                               //
    //////////////////////////////////////////////////////////////////////
    function getAddress() public view returns (address) {
        return address(powersFactory);
    }

    //////////////////////////////////////////////////////////////////////
    //                        CONSTITUTION                              //
    //////////////////////////////////////////////////////////////////////
    function _createConstitution(
        address primaryLayer,
        address governed721,
        address activityToken,
        address nominees,
        uint16 mintPoapTokenId, 
        uint16 requestAllowancePhysicalLayerId
    ) internal {
        mandateCount = 3; // resetting mandate count. 
        //////////////////////////////////////////////////////////////////////
        //                              SETUP                               //
        //////////////////////////////////////////////////////////////////////

        // setup role labels // 
        calldatas = new bytes[](10);
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 0, "Setup Initiator", "");  
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, type(uint256).max, "Public", ""); 
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Attendee", ""); 
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Steward", ""); 
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Legal Interfacer", "");
        calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 6, "Primary Layer", "");
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, cedars);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, cedars);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 6, primaryLayer); 
        calldatas[9] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateCount + 1); // revoke mandate 1 after use. 

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "PresetActions_OnOwnPowers"),
                config: abi.encode(calldatas),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      EXECUTIVE MANDATES                          //
        //////////////////////////////////////////////////////////////////////
        // £NB: Minting and setting the URI no all managed externally from this DAO. 
        // The artist has to assign the layer as approved to transfer artworks. 
  
        // StewardS FORCE SELL NFT ART WORK //
        uint16[] memory mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Sell NFT artwork: This flow allows Stewards to sell NFT art works, automatically transferring the NFT and distributing payments.",
            mandateIds: mandateIds
        }));

        // NOTE: Owners of art works can always decide to sell art work on their own account. Income of sell will be distributed in both cases. 
        inputParams = new string[](4); 
        inputParams[0] = "address oldOwner";
        inputParams[1] = "address newOwner";
        inputParams[2] = "uint256 TokenId";
        inputParams[3] = "bytes Data"; // encoded PaymentToken + quantity + nonce. 
        // Note that technically the Physical Layer can pay for sale if the buyer paid the Sub-DAO directly. It would result in the layer owning the NFT, while buyer has the physical artwork. 

        // NB: this will only work if the physical layer has been approved by the artist to transfer the art work NFTs. This is to ensure that artists have control over which art works can be sold through the layer.
        mandateCount++;
        conditions.allowedRole = 2; // Stewards. 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Sell NFT artwork: Stewards can sell NFT art works, which will automatically transfer from the owner of the NFT to the buyer and distribute payments according to splits set by the governed721DAO.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    governed721,
                    Governed721.safeTransferFrom.selector,
                    inputParams
                ),
                conditions: conditions
            })
        ); 
        delete conditions;

        // REQUEST ALLOWANCES FROM PRIME DAO //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Request Allowances from Primary Layer: This flow includes the veto and request of allowances from the Primary Layer.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](5);
        inputParams[0] = "address Sub-DAO";
        inputParams[1] = "address Token";
        inputParams[2] = "uint96 allowanceAmount";
        inputParams[3] = "uint16 resetTimeMin";
        inputParams[4] = "uint32 resetBaseMin";
 
        // Stewards: Veto request allowance from Primary Layer
        mandateCount++;
        conditions.allowedRole = 2; // Steward 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto request allowance: Stewards can veto a request for additional allowance", //
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Legal Interfacer: Request allowance from Primary Layer
        mandateCount++;
        conditions.allowedRole = 3; // Legal Interfacer 
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request allowance: Repository admins can request an allowance from the Primary Layer Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ExternalAction_Simple"),
                config: abi.encode(
                    address(primaryLayer), // target contract
                    requestAllowancePhysicalLayerId, // parent mandate id (the request allowance at primary DAO mandate)
                    "Requesting allowance from Primary Layer Safe Treasury",
                    inputParams // dynamic params (the input params of the parent mandate)
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // PAYMENT OF RECEIPTS //
        mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Payment of Receipts: This flow allows Stewards to submit and approve payment of receipts.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](3);
        inputParams[0] = "address Token";
        inputParams[1] = "uint256 Amount";
        inputParams[2] = "address PayableTo";

        // Stewards: Submit & approve Payment of Receipt
        mandateCount++;
        conditions.allowedRole = 2; // Stewards can propose and vote on receipts.   
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 67;
        conditions.quorum = 50; 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Submit & Approve payment of receipt: Execute a transaction from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "SafeAllowance_Transfer"),
                config: abi.encode(helperConfig.getSafeAllowanceModule(block.chainid), treasury),
                conditions: conditions
            })
        );
        delete conditions;

        // MINT POAPS FOR ATTENDEES //
        mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Mint POAPs for Attendees: This flow allows Stewards to mint POAPs for event attendees.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "address To";

        // Stewards: Mint POAPs for attendees
        // Note: for now this is managed through a bespoke Soulbound1155 contract. 
        // Before a physical event is organised, this should be implemented through either POAP.xyz, or IYK protocols.    
        mandateCount++;
        conditions.allowedRole = 1; // = Stewards
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Mint POAP: Any Steward can mint a POAP.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ExternalAction_Simple"),
                config: abi.encode(
                    address(primaryLayer),
                    uint16(mintPoapTokenId), // parent mandate id (the mint POAP token at primary DAO mandate)
                    "Requesting minting of POAP from Primary Layer",
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // MISCELLANEOUS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Miscellaneous powers: This flow includes updating the URI and recovering tokens sent to the DAO by mistake.",
            mandateIds: mandateIds
        }));

        // UPDATE URI //
        inputParams = new string[](1);
        inputParams[0] = "string newUri"; 

        // Stewards: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Stewards
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Update URI: Set allowed token for Physical Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    address(0), // target address is its own powers contract
                    Powers.setUri.selector, // function selector to call
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Stewards. Any Steward can call this mandate.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the DAO can be recovered by sending them to the treasury",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Safe_RecoverTokens"), // maybe functionality has to change slightly: have token to be transferred as input param. 
                config: abi.encode(
                    treasury, 
                    helperConfig.getSafeAllowanceModule(block.chainid) // allowance module address
                ),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      ELECTORAL MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // CLAIM ATTENDEE ROLE //   
        mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Claim Attendee Role: This flow allows anyone to become a member if they have sufficient activity tokens.",
            mandateIds: mandateIds
        }));

        // I think this will work. Still needs to be tested though. 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request Membership: Anyone can become a member if they have sufficient activity token from the DAO 1 tokens during the last 15 days.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "GovernedToken_GatedAccess"),
                config: abi.encode(
                    activityToken, // soulbound token contract
                    1, // attendee role Id
                    0, // checks if token is from address that holds role Id 0 (meaning the admin, which is the DAO itself).
                    uint48(daysToBlocks(15, helperConfig.getBlocksPerHour(block.chainid))), // look back period in blocks = 15 days.
                    uint48(1) // number of tokens required. Only one POAP needed for membership.
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // SELECT StewardS //
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4; 

        flows.push(PowersTypes.Flow({
            nameDescription: "Select Stewards: This flow allows for the nomination, selection, and peer election of Stewards.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "bool Nominate"; 

        // anybody: do ZKP check: age >= 18 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public. anyone can pass the ZKP check to propose a legal Interfacer for the Physical Layer.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "ZK-Passport Check Age: Anyone over the age of 18 can propose to be a Steward for the Physical Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ZKPassport_Check"),
                config: abi.encode(
                    inputParams,
                    helperConfig.getZkPassportRootRegistry(block.chainid), // the address of the ZK-Passport root registry contract, which is needed to verify the ZKPs. This is set in the helper config for each chain.
                    60 * 60 * 24 * 90, // the time window in which the ZKP proof needs to have been created. This is three months.
                    false, // facematch not required (for now) 
                    ZKPassportHelper.isAgeAboveOrEqual.selector,  
                    abi.encode(uint8(18)) // the input for the zkp check (age > 18) 
                    ),
                conditions: conditions
            })
        );
        delete conditions;

        // Anyone: Nominate for selection to be Steward.
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        conditions.needFulfilled = mandateCount - 1; // need the previous ZKP check mandate to be fulfilled to nominate for Steward selection.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Nominate for selection: any member can nominate to be selected for Steward role.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Nominate"),
                config: abi.encode(
                    nominees // election list contract
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // legal reps: force revoke nomination.
        mandateCount++;
        inputParams = new string[](1);
        inputParams[0] = "address Nominee"; // the address of the nominee whose nomination is to be revoked.

        conditions.allowedRole = 3; // = legal Interfacers.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke nomination for election: Legal Interfacers can revoke nominations for Steward elections.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode(
                    nominees, // election list contract
                    Nominees.revokeNomination.selector,
                    abi.encode(), // params before
                    inputParams,
                    abi.encode(false) // params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Legal Interfacers: adopt peer select mandate to select Stewards from the pool of nominees. 
        PowersTypes.MandateInitData[] memory initData = new PowersTypes.MandateInitData[](1);
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = simple majority
        conditions.quorum = 80; // = 80% quorum
        initData[0] = PowersTypes.MandateInitData({
                nameDescription: "Select Stewards: Legal Interfacers can select Stewards from the pool of nominees.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "PeerSelect"),
                config: abi.encode(
                    uint8(3), // numberToSelect
                    uint256(2), // RoleId for Stewards
                    nominees // election list contract // 
                ),
                conditions: conditions
            });
        delete conditions;

        // ASSIGN LEGAL REPS //
        mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign Legal Interfacers: This flow allows the Primary Layer to assign legal Interfacers.",
            mandateIds: mandateIds
        }));

        // Primary Layer: assign Legal Interfacer. 
        mandateCount++;
        inputParams = new string[](2);
        inputParams[0] = "address Interfacer"; 
        conditions.allowedRole = 6; // = Primary Layer.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Legal Interfacers: Primary Layer can assign legal Interfacers, who have the power to adopt and revoke executive mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(0), // target is its own powers contract
                    IPowers.assignRole.selector,
                    abi.encode(3), // roleId of Legal Interfacer role
                    inputParams,
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;
        assignRepsMandateId = mandateCount; 
        
        //////////////////////////////////////////////////////////////////////
        //                        REFORM MANDATES                           //
        //////////////////////////////////////////////////////////////////////

        // ADOPT MANDATES //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Adopt Mandates: This flow allows for the adoption of new mandates, initiated by Members, adopted by Stewards, and subject to veto by the Primary Layer.",
            mandateIds: mandateIds
        }));

        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Members: initiate Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initiate Adopting Mandates: Members can initiate adopting new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        // primaryLayer: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 6; // primaryLayer = role 6. 
        conditions.needFulfilled = mandateCount - 1;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: primaryLayer can veto proposals to adopt new mandates", 
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Stewards: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Stewards
        conditions.needFulfilled = mandateCount - 2;
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Adopt new Mandates: Stewards can adopt new mandates into the organization",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Adopt_Mandates"),
                config: abi.encode(),
                conditions: conditions
            })
        );
        delete conditions;

        // LEGAL REPS CAN PAUSE AND RESTART MANDATES //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Executive Mandates Management: This flow allows Legal Interfacers to adopt or revoke executive mandates, effectively controlling the DAO's functional state.",
            mandateIds: mandateIds
        }));

        // (Effectively giving power to pause functioning of the layer). 
        // Mandates to be adopted / revoked: (£todo: for now this is a placeholder, need to decide which Mandates to place here!).  
        string[] memory mandatesToPause = new string[](5);
        mandatesToPause[0] = "Sell NFT artwork";
        mandatesToPause[1] = "Submit & approve payment of receipt";
        mandatesToPause[2] = "Mint POAP: Any Steward can mint a POAP";
        mandatesToPause[3] = "Vote on 'Merit' NFT proposals";
        mandatesToPause[4] = "Update URI";
        (uint16[] memory indexFlows16, uint16[] memory indexMandates16) = findIndices(mandatesToPause, constitution, flows);
        
        uint8[] memory indexFlows = new uint8[](indexFlows16.length);
        uint8[] memory indexMandates = new uint8[](indexMandates16.length);
        for(uint256 i = 0; i < indexFlows16.length; i++) {
            indexFlows[i] = uint8(indexFlows16[i]);
            indexMandates[i] = uint8(indexMandates16[i]);
        }

        // Legal Interfacers: Pause Mandates
        mandateCount++;
        conditions.allowedRole = 3; // Legal Interfacers
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Pause Mandates: Legal Interfacers can pause mandates in the organization",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "PauseMandates"),
                config: abi.encode(
                    indexFlows,
                    indexMandates
                ),
                conditions: conditions
            })
        );
        delete conditions;
    }
}
