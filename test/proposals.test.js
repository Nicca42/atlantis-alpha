const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Proposal contract isolation testing", () => {
    var deployer, core;
    var core, coordinator, executable, proposals, testExecutable;

    beforeEach(async () => {
        [
            deployer,
            core
        ] = await ethers.getSigners();

        const Core = await ethers.getContractFactory("Core");
        const Coordinator = await ethers.getContractFactory("Coordinator");
        const Executable = await ethers.getContractFactory("Executables");
        const Proposals = await ethers.getContractFactory("Proposals")
        const TestExecutable = await ethers.getContractFactory("TestExecutable");

        core = await Core.deploy();
        executable = await Executable.deploy(core.address);
        coordinator = await Coordinator.deploy(core.address);
        proposals = await Proposals.deploy(core.address);
        testExecutable = await TestExecutable.deploy();

        await core.initialise(
            coordinator.address,
            executable.address,
            proposals.address,
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000"
        );
    });

    it("Proposals", async () => {});

    let testExe = {};
});