const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vote Booth contract isolation testing", () => {
    var deployer, proposer, voter;
    var core, coordinator, executable, proposals, voteWeight, votingBooth, 
        voteStorage, simpleMajority, testExecutable;

    beforeEach(async () => {
        [
            deployer,
            proposer,
            voter
        ] = await ethers.getSigners();

        const Core = await ethers.getContractFactory("Core");
        const Coordinator = await ethers.getContractFactory("Coordinator");
        const Executable = await ethers.getContractFactory("Executables");
        const Proposals = await ethers.getContractFactory("Proposals");
        const VoteWeight = await ethers.getContractFactory("VoteWeight");
        const VotingBooth = await ethers.getContractFactory("VotingBooth");
        const VoteStorage = await ethers.getContractFactory("VoteStorage");
        const SimpleMajority = await ethers.getContractFactory("SimpleMajority");
        const TestExecutable = await ethers.getContractFactory("TestExecutable");

        core = await Core.deploy();
        executable = await Executable.deploy(core.address);
        coordinator = await Coordinator.deploy(core.address);
        proposals = await Proposals.deploy(core.address);
        voteWeight = await VoteWeight.deploy(core.address);
        simpleMajority = await SimpleMajority.deploy(core.address);
        votingBooth = await VotingBooth.deploy(
            core.address,
            simpleMajority.address,
            testExe.initialVoteType,
            testExe.voteFormat,
        );
        voteStorage = await VoteStorage.deploy(core.address);
        testExecutable = await TestExecutable.deploy();

        await core.initialise(
            coordinator.address,
            executable.address,
            proposals.address,
            voteWeight.address,
            votingBooth.address,
            voteStorage.address
        );
    });

    it("Vote Booth", async () => {
        let exe = await (await executable.connect(proposer).createExe(
            [testExecutable.address, testExecutable.address],
            testExe.funcSig,
            testExe.bytes,
            testExe.values,
            testExe.descriptionExe
        )).wait();

        let exeID = exe.events[0].args.exeID;

        let prop = await (await proposals.connect(proposer).createPropWithExe(
            testExe.descriptionProp,
            simpleMajority.address,
            testExe.bytes[0],
            exeID
        )).wait();

        let propID = prop.events[0].args.propID.toString();

        let encodedVote = await testExecutable.encodeBool(1);
        console.log(encodedVote)

        // await simpleMajority.connect(voter).vote(propID, encodedVote, voter.address);

        console.log("test")

        let vote = await (await votingBooth.connect(voter).vote(propID, "0x01")).wait();

        console.log(vote.events)
    });

    let testExe = {
        funcSig: ["setNumber(uint256)", "setBytes(bytes32)"],
        bytes: [
            "0x0000000000000000000000000000000000000000000000000000000000000001",
            "0x0000000000000000000000000000000000000000000000000000000000000001"
        ],
        calldata: [
            "0x3fb5c1cb0000000000000000000000000000000000000000000000000000000000000001",
            "0xe6748da90000000000000000000000000000000000000000000000000000000000000001"
        ],
        values: [0, 0],
        descriptionExe: "A test executable.",
        descriptionProp: "A test proposal.",
        initialVoteType: "0x0000000000000000000000000000000000000000000000000000000000000001",
        voteFormat: "bool"
    };
});