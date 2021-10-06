const { expect } = require("chai");
const { ethers } = require("hardhat");

// TODO move this to a deployment script of basic system

describe("Start here: Intro to the Atlantis framework", () => {
    var deployer, proposer, voter_one, voter_two, voter_three;
    var core, coordinator, executable, proposals, voteWeight, votingBooth, 
        simpleMajority, testExecutable, govToken, repToken;
    var Core, Coordinator, Executable, Proposals, VotingBooth, VoteWeight, 
        SimpleMajority, TestExecutable, Token;
    var voteTypeID, exeID, propID;

    before(async () => {
        [
            deployer,
            proposer,
            voter_one,
            voter_two,
            voter_three
        ] = await ethers.getSigners();

        console.log(
            "\nWelcome!\n" +
            "\nThis serves as an introduction to a basic Atlantis DAO. Atlantis is designed " +
            "\nto be highly modular and extendable. As such you can replace any contract in the " + 
            "\nsystem. This test file demonstrates the most basic Atlantis DAO. We will run " +
            "\nthrough deployment, turning the system on as well as a basic:" + 
            "\n\n proposal -> voting -> execution cycle.\n"
        );

        console.log("1️⃣  First things first we need to deploy all the contracts...\n");

        // Here we are getting the contract information for deployment
        Core = await ethers.getContractFactory("Core");
        Coordinator = await ethers.getContractFactory("Coordinator");
        Executable = await ethers.getContractFactory("Executables");
        Proposals = await ethers.getContractFactory("Proposals");
        VotingBooth = await ethers.getContractFactory("VotingBooth");
        VoteWeight = await ethers.getContractFactory("VoteWeight");
        SimpleMajority = await ethers.getContractFactory("SimpleMajority");
        TestExecutable = await ethers.getContractFactory("TestExecutable");
        Token = await ethers.getContractFactory("Token");
    });

    it("Deployed the base contracts", async () => {
        core = await Core.deploy();
        console.log("🛠  Core deployed");
        coordinator = await Coordinator.deploy(core.address);
        console.log("🛠  Coordinator deployed");
        executable = await Executable.deploy(core.address);
        console.log("🛠  Executables deployed");
        proposals = await Proposals.deploy(core.address);
        console.log("🛠  Proposals deployed");
        votingBooth = await VotingBooth.deploy(core.address);
        console.log("🛠  Voting Booth deployed");
        voteWeight = await VoteWeight.deploy(core.address);
        console.log("🛠  Vote Weight deployed");
        simpleMajority = await SimpleMajority.deploy(core.address);
        console.log("🛠  Consensus mechanism: Simple Majority deployed\n");
        testExecutable = await TestExecutable.deploy();
        govToken = await Token.deploy("gov token", "GOVT");
        repToken = await Token.deploy("rep token", "REPT");
    });

    it("Switched the core module on", async () => {
        console.log("\n2️⃣  Now we need to switch on the core...\n");
        await core.initialise(
            coordinator.address,
            executable.address,
            proposals.address,
            voteWeight.address,
            votingBooth.address
        );
    });
    
    it("Switched the Voting Booth module on", async () => {

        console.log("\n3️⃣  After the core is on we need to switch on the Voting Booth...\n");
        
        // Here we are are getting the bytes32 of the vote type. This will be
        // used as the identifier for the consensus mechanism. 
        voteTypeID = await testExecutable.encodeBytes32("SIMPLE_MAJORITY");
        
        // Init voting booth with consensus mechanism
        await votingBooth.initialise(
            simpleMajority.address,
            voteTypeID,
            "bool"
        );
    });

    it("Switched the Vote Weight module on", async () => {
        console.log("\n4️⃣  Next is the Vote Weight...\n");
        
        console.log(
            "To switch on our Vote Weight we need to deploy our systems' tokens. For this" +
            "\nsystem we will be using a simple two token vote weight. There will be a liquid" +
            "\n(tradable) governance token, as well as an illiquid (non-transferable)" +
            "\nreputation token. These will be weighted equally in a simple equation:\n" + 
            "\n vote_weight = (gov_token * rep_token) / 2\n"
        );

        // Note that we do not need to pass in the vote weight equation as this is
        // specified within the vote weight contract itself. 
        await voteWeight.initialise(
            govToken.address,
            repToken.address
        );

        // The vote weight module does not have to use tokens for governance. It
        // can use anything! If you wanted to deploy a system that is more centralised
        // the vote weight could have a list of addresses where the vote weight is 1,
        // and every other address would have a vote weight of 0, or revert. 
        // The vote weight could act as a multi-sig in this way, requiring a 
        // majority of a small subset of voters. 
    });

    it("Distributed tokens to voters", async () => {
        console.log("\n5️⃣  Distribute governance and reputation token...\n");

        await govToken.mint(proposer.address, 10);
        await govToken.mint(voter_one.address, 10);
        await govToken.mint(voter_two.address, 100);
        await govToken.mint(voter_three.address, 1000);

        await repToken.mint(proposer.address, 1000);
        await repToken.mint(voter_one.address, 100);
        await repToken.mint(voter_two.address, 10);
        await repToken.mint(voter_three.address, 1);
    });

    it("Created an executable", async () => {
        console.log("\n6️⃣  Create a executable...\n");

        // If you want to test the parameter encoding you can uncomment this
        // let encodedFunctionParameters = await testExecutable.encodeBytes(
        //     proposer.address,
        //     1000
        // );
        // console.log(encodedFunctionParameters.toString());

        let exe = await (await executable.connect(proposer).createExe(
            [repToken.address],
            ["mint(address,uint256)"],
            ["0x70997970c51812dc3a010c7d01b50e0d17dc79c800000000000000000000000000000000000000000000000000000000000003e8"],
            [0],
            "Distributing reputation rewards to proposer."
        )).wait();

        exeID = exe.events[0].args.exeID;

        console.log("Exe created. ID: ", exeID.toString(), "\n");
    });

    it("Created a proposal", async () => {
        console.log("\n7️⃣  Create a proposal...\n");

        let proposal = await (await proposals.connect(proposer).createPropWithExe(
            "Proposal to distribute reputation rewards to proposer.",
            voteTypeID.toString(),
            exeID
        )).wait();

        propID = proposal.events[1].args.propID.toString();
        console.log("Prop created. ID: ", propID.toString(), "\n");
    });
    
    it("Voted on proposal", async () => {
        console.log("\n8️⃣  Vote on the proposal...\n");
        
        
        // TODO
    });

    it("Executed proposal", async () => {
        console.log("\n9️⃣  Execute the proposal...\n");
        
        // TODO
    });
});