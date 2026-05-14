// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { console2 } from "forge-std/console2.sol";
import { DeploySetup } from "./DeploySetup.s.sol";
import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { ElectionRegistry } from "@lib/powers-monorepo/solidity/src/helpers/ElectionRegistry.sol";

// NB NOTES - the logic should be the following: 
// Roles should reflect roles in github repo: 
// keeping them alligned through social pressure.
// Rage quit option by forking repo and reassigning repo to Powers.  
// Participation assigned through github contribs + steward approval. 

contract DigitalLayer is DeploySetup {
    PowersTypes.Conditions conditions;
    PowersTypes.Flow[] flows;

    PowersTypes.MandateInitData[] constitution; 
    Powers powers; 
    uint16 assignConvergenceLayer;

    //////////////////////////////////////////////////////////////////////
    //                        INITIALISATION                            //
    //////////////////////////////////////////////////////////////////////
    function run() public {
        console2.log("Deploying Digital Layer...");
        vm.startBroadcast();
            powers = new Powers(
                "Digital Layer", // name
                string.concat(baseURI, "digitalLayer.json"),
                helperConfig.getMaxCallDataLength(block.chainid), // max call data length
                helperConfig.getMaxReturnDataLength(block.chainid), // max return data length
                helperConfig.getMaxExecutionsLength(block.chainid) // max executions length
            );
        vm.stopBroadcast();

        console2.log("Digital Layer deployed at:", address(powers));

        // runnning constute script with empty data to calculate assignConvergenceLayerMandateId. - very inefficient..
        _createConstitution(
            address(0), // digitalLayer --- IGNORE ---
            address(0), // ideasLayerFactory --- IGNORE ---
            0 // assignConvergenceLayerMandateId --- IGNORE ---
         );
    }

    //////////////////////////////////////////////////////////////////////
    //                          CONSTITUTE                              //
    //////////////////////////////////////////////////////////////////////
    function constitutePowers(
        address primaryLayer,
        address electionRegistry, 
        uint16 requestAllowanceDigitalLayerId
    ) public {
        delete constitution; // reset constitution to avoid issues with the double run of _createConstitution.
        _createConstitution(primaryLayer, electionRegistry, requestAllowanceDigitalLayerId);
        
        for (uint256 i = 0; i < constitution.length; i += PACKAGE_SIZE) {
            uint256 packageLength = constitution.length - i < PACKAGE_SIZE ? constitution.length - i : PACKAGE_SIZE;
            PowersTypes.MandateInitData[] memory constitutionPart = new PowersTypes.MandateInitData[](packageLength);
            for (uint256 j = 0; j < constitutionPart.length; j++) {
                constitutionPart[j] = constitution[i + j];
            }
            vm.startBroadcast();
            powers.constitute(constitutionPart);
            vm.stopBroadcast();
        } 
        vm.startBroadcast();
        powers.closeConstitute(cedars, flows); // set msg.sender as admin);
        vm.stopBroadcast();
    }

    //////////////////////////////////////////////////////////////////////
    //                            GETTERS                               //
    //////////////////////////////////////////////////////////////////////
    function getAddress() public view returns (address) {
        return address(powers);
    }

    function getAssignConvergenceLayer() public view returns (uint16) {
        return assignConvergenceLayer;
    }

    //////////////////////////////////////////////////////////////////////
    //                        CONSTITUTION                              //
    //////////////////////////////////////////////////////////////////////
    function _createConstitution(
        address primaryLayer,
        address electionRegistry,
        uint16 requestAllowanceDigitalLayerId
    ) internal {
        mandateCount = 0; // resetting mandate count.

        //////////////////////////////////////////////////////////////////////
        //                              SETUP                               //
        //////////////////////////////////////////////////////////////////////
        calldatas = new bytes[](11);
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 0, "Admin", "");  
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, type(uint256).max, "Read", ""); 
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Write", ""); 
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Maintain", "");   
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 6, "Primary Layer", ""); 
        calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 7, "Convergence Layer", "");
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, cedars);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, cedars);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, cedars);
        calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 6, primaryLayer);
        calldatas[10] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateCount + 1); // revoke mandate 1 after use.

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "PresetActions_OnOwnPowers"),
                config: abi.encode(calldatas),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      EXECUTIVE MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // REQUEST ALLOWANCES FROM PRIMARY LAYER //
        uint16[] memory mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Request Allowances from Primary Layer: This flow includes the veto and request of allowances from the Primary Layer.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](5);
        inputParams[0] = "address DigitalLayer";
        inputParams[1] = "address Token";
        inputParams[2] = "uint96 allowanceAmount";
        inputParams[3] = "uint16 resetTimeMin";
        inputParams[4] = "uint32 resetBaseMin";
 
        // Writers: Veto request allowance from Primary Layer
        mandateCount++;
        conditions.allowedRole = 1; // Writers 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto request allowance: Writers can veto a request for additional allowance", //
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Repository admins: Request allowance from Primary Layer
        mandateCount++;
        conditions.allowedRole = 2; // Repository admins 
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request allowance: Repository admins can request an allowance from the Primary Layer Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ExternalAction_Simple"),
                config: abi.encode(
                    address(primaryLayer), // target contract
                    requestAllowanceDigitalLayerId, // parent mandate id (the request allowance at primary Layer mandate)
                    "Requesting allowance from Primary Layer Safe Treasury",
                    inputParams // dynamic params (the input params of the parent mandate)
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // PAYMENT OF GENERAL RECEIPTS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Payment of Receipts: This flow includes the submission, oking, and approval of receipts for payment reimbursement.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](3);
        inputParams[0] = "address Token";
        inputParams[1] = "uint256 Amount";
        inputParams[2] = "address PayableTo";

        // Public: Submit a receipt (Payment Reimbursement - After Action)
        mandateCount++;
        conditions.allowedRole = 1; // Any account with writer role can submit a receipt..
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Submit a Receipt: Anyone can submit a receipt for payment reimbursement.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Repository admins: Approve Payment of Receipt
        mandateCount++;
        conditions.allowedRole = 2; // Repository admins
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 67;
        conditions.quorum = 50;
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Approve payment of receipt: Execute a transaction from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "SafeAllowance_Transfer"),
                config: abi.encode(helperConfig.getSafeAllowanceModule(block.chainid), treasury),
                conditions: conditions
            })
        );
        delete conditions;

        // REQUESTS FROM CONVERGENCE LAYER //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Request from Convergence Layer: This flow handles requests for project payments coming from the Convergence Layer.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](3);
        inputParams[0] = "address Token";
        inputParams[1] = "uint256 Amount";
        inputParams[2] = "address PayableTo";

        // Public: Submit a receipt (Payment Reimbursement - After Action)
        mandateCount++;
        conditions.allowedRole = 7; // Any Convergence Layer
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Submit a Request: Any Convergence Layer can submit a request for project payments in their name.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Repository admins: Approve Payment of Receipt
        mandateCount++;
        conditions.allowedRole = 2; // Repository admins
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 61;
        conditions.quorum = 40;
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Approve payment for request: Executes a transaction from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "SafeAllowance_Transfer"),
                config: abi.encode(helperConfig.getSafeAllowanceModule(block.chainid), treasury),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      ELECTORAL MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // ASSIGN WRITE ROLE // -- on the basis of contributions to website
        // mandateIds = new uint16[](2);
        // mandateIds[0] = mandateCount + 1;
        // mandateIds[1] = mandateCount + 2;

        // flows.push(PowersTypes.Flow({
        //     nameDescription: "Assign Write Role: This flow allows users to apply for and claim Write roles based on their GitHub contributions.",
        //     mandateIds: mandateIds
        // }));

        // TODO: needs to be configured with github repo details etc.
        // string[] memory inputParams = new string[](3);
        // inputParams[0] = "string Branch"; // can be anything
        // inputParams[1] = "string CommitHash"; // can be anything

        // // Public: Apply for Writer role
        // mandateCount++;
        // conditions.allowedRole = type(uint256).max; // Public
        // conditions.throttleExecution = minutesToBlocks(3, helperConfig.getBlocksPerHour(block.chainid)); // to avoid spamming, the mandate is throttled.
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Apply for Writer Role: Anyone can claim Writer roles based on their GitHub contributions to the Cultural Stewards's repository (WIP)", // crrently the path is set at cedars/powers
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ChainlinkFunctions_Open"),  
        //         config: abi.encode(
        //             "const branch = args[0];\nconst commitHash = args[1];\n\nif (!branch || !commitHash || !folderName) {\n    throw Error(\"Missing required args\");\n}\n\nconst url = `https://powers-utils.vercel.app/api/check-commit/`; \n\nconst githubRequest = Functions.makeHttpRequest({\n    url: url,\n    method: \"GET\",\n    timeout: 9000, \n    params: {\n        repo: \"publius-projects/cultural-stewards\",\n        branch: branch,\n        commitHash: commitHash,\n        maxAgeCommitInDays: 90,\n        folderName: \"contracts\"\n    }\n});\n \nconst githubResponse = await githubRequest;\nif (githubResponse.error || !githubResponse.data || !githubResponse.data.data || !githubResponse.data.data.signature) {\n    throw Error(`Request Failed: ${githubResponse.error.message}`);\n}\n\nreturn Functions.encodeString(githubResponse.data.data.signature", // js script;
        //             inputParams, // dynamic params (the input params of the parent mandate)
        //             helperConfig.getChainlinkFunctionsSubscriptionId(block.chainid),
        //             helperConfig.getChainlinkFunctionsGasLimit(block.chainid),
        //             helperConfig.getChainlinkFunctionsDonId(block.chainid)
        //         ),
        //         conditions: conditions
        //     })
        // );
        // delete conditions;

        // // Public: Claim Writer Role
        // mandateCount++;
        // conditions.allowedRole = type(uint256).max; // Public
        // conditions.needFulfilled = mandateCount - 1; // must have applied for Writer role.
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Claim Writer Role: Following a successful initial claim, Writers can get Writer role assigned to their account.",
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "Github_AssignRoleWithSig"),
        //         config: abi.encode(), // empty config
        //         conditions: conditions
        //     })
        // );
        // delete conditions;

        // REVOKE Writer //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Revoke Writer: This flow allows Writers to veto and Executives to revoke Writer role.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "address WriterAddress";

        // Writers: veto Revoke Writer
        mandateCount++;
        conditions.allowedRole = 1; // = Writers
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Revoke Writer: Writers can veto revoking Writer from other Writers.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Revoke Writer
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Writer: Executives can revoke Writer role.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(powers), 
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(1), // params before (role id 1 = Writers) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // ELECT Repository admins //
        mandateIds = new uint16[](6);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;
        mandateIds[4] = mandateCount + 5;
        mandateIds[5] = mandateCount + 6;
        
        flows.push(PowersTypes.Flow({
            nameDescription: "Elect Repository Setup Initiators: This flow includes the creation, voting, tallying, and cleanup of an election for Repository Setup Initiators.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "string Title"; 

        // Writers: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Writers
        conditions.throttleExecution = minutesToBlocks(120, helperConfig.getBlocksPerHour(block.chainid)); // = once every 2 hours
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create a Convener election: an election for the convener role can be initiated be any Writer. After an election is created, participants have 5 minutes to nominate themselves.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Simple"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    ElectionRegistry.createElection.selector, // selector
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Writers: Open Vote for election
        mandateCount++;
        conditions.allowedRole = 1; // = Writers
        conditions.needFulfilled = mandateCount - 1; // = Create election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Open voting for Convener election: After five minutes of initiating an election, Writers can open the vote for a convener election. This will create a dedicated vote mandate. The vote will stay open for five minutes.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_CreateVoteMandate"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_Vote"), // the vote mandate address
                    1, // the max number of votes a voter can cast
                    1 // the role Id allowed to vote (Writers)
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Writers: Tally election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Open Vote election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Tally Convener elections: After five minutes of opening the vote, tally the results and assign the Convener role to the winners.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_Tally"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    2, // RoleId for Repository admins
                    3 // Max role holders
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Writers: clean up election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Tally election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Clean up Convener election: After five minutes of tallying the results, clean up related mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeMandate.selector, // function selector to call
                    abi.encode(), // params before
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 2, // parent mandate id (the open vote mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Writers: Nominate for Executive election
        mandateCount++;
        conditions.allowedRole = 1; // = Writers (should be Repository admins according to MD, but code says Writers)
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Nominate for election: any Writer can nominate for an election.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_Nominate"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    true // nominate as candidate
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Writers revoke nomination for Executive election.
        mandateCount++;
        conditions.allowedRole = 1; // = Writers (should be Repository admins according to MD, but code says Writers) 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke nomination for election: any Writer can revoke their nomination for an election.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_Nominate"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    false // revoke nomination
                ),
                conditions: conditions
            })
        );
        delete conditions;


        //////////////////////////////////////////////////////////////////////
        //                        REFORM MANDATES                           //
        //////////////////////////////////////////////////////////////////////

        // ADOPT MANDATES //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Adopt Mandates: This flow allows for the adoption of new mandates, initiated by Writers, adopted by Repository admins, and subject to veto by the Primary Layer.",
            mandateIds: mandateIds
        }));

        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Writers: initiate Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Writers
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initiate Adopting Mandates: Writers can initiate adopting new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        // primaryLayer: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 6; // primaryLayer
        conditions.needFulfilled = mandateCount - 1;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: primaryLayer can veto proposals to adopt new mandates", 
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        // // Repository admins: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Repository admins
        conditions.needFulfilled = mandateCount - 2;
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Adopt new Mandates: Repository admins can adopt new mandates into the organization",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "Adopt_Mandates"),
                config: abi.encode(),
                conditions: conditions
            })
        );
        delete conditions;


        // UPDATE URI //
        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // Repository admins: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Repository admins
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Update URI: Set allowed token for Convergence Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Simple"),
                config: abi.encode(
                    address(powers), // target address is its own powers contract
                    Powers.setUri.selector, // function selector to call
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Repository admins. Any convener can call this mandate.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the Layer can be recovered by sending them to the treasury",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "Safe_RecoverTokens"),
                config: abi.encode(
                    treasury, // this should be the safe treasury!
                    helperConfig.getSafeAllowanceModule(block.chainid) // allowance module address
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // ASSIGN: CONVERGENCE LAYER ROLE
        inputParams = new string[](1);
        inputParams[0] = "address ConvergenceLayer";

        mandateCount++;
        conditions.allowedRole = 6; // = Primary Layer.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Convergence Layer Role: The Primary Layer can assign the Convergence Layer role to accounts of their choosing. This is necessary for the Convergence Layer to be able to submit requests for payments.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(0), 
                    IPowers.assignRole.selector, // function selector to call
                    abi.encode(7), // params before (role id 1 = Writers) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions; 
        assignConvergenceLayer = mandateCount; 
    }
}
