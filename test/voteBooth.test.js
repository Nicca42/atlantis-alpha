const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vote Booth contract isolation testing", () => {
    var deployer, core;
    var core, coordinator, executable, proposals, voteWeight, votingBooth, voteStorage, testExecutable;

    beforeEach(async () => {
        [
            deployer,
            core
        ] = await ethers.getSigners();

        const Core = await ethers.getContractFactory("Core");
        const Coordinator = await ethers.getContractFactory("Coordinator");
        const Executable = await ethers.getContractFactory("Executables");
        const Proposals = await ethers.getContractFactory("Proposals");
        const VoteWeight = await ethers.getContractFactory("VoteWeight");
        const VotingBooth = await ethers.getContractFactory("VotingBooth");
        const VoteStorage = await ethers.getContractFactory("VoteStorage");
        const TestExecutable = await ethers.getContractFactory("TestExecutable");

        core = await Core.deploy();
        executable = await Executable.deploy(core.address);
        coordinator = await Coordinator.deploy(core.address);
        proposals = await Proposals.deploy(core.address);
        voteWeight = await VoteWeight.deploy(core.address);
        votingBooth = await VotingBooth.deploy(core.address);
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

    it("Vote Booth", async () => {});

    let testExe = {};
});