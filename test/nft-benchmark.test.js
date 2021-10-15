// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("NFT testing", () => {
//     var deployer, minter, from, to;
//     let ozToken, atlantisToken;

//     beforeEach(async () => {
//         [
//             deployer,
//             minter,
//             from,
//             to
//         ] = await ethers.getSigners();

//         const OzToken = await ethers.getContractFactory("Token721");
//         const AtlantisToken = await ethers.getContractFactory("AtlantisNft");

//         ozToken = await OzToken.deploy("OZ Token", "OZT");
//         atlantisToken = await AtlantisToken.deploy("Atlantis Token", "AT");
//     });

//     describe("Token testing", async () => {
//         it("Benchmark", async () => {
//             await ozToken.connect(minter).mint(minter.address);

//             await atlantisToken.connect(minter).createTokenType(
//                 "0x53494d504c455f4d414a4f524954590000000000000000000000000000000000",
//                 true,
//                 [minter.address]
//             );

//             await atlantisToken.connect(minter).mint(
//                 "0x53494d504c455f4d414a4f524954590000000000000000000000000000000000",
//                 minter.address
//             );

//             await ozToken.connect(minter).transferFrom(
//                 minter.address,
//                 to.address,
//                 1
//             );

//             await atlantisToken.connect(minter).transferFrom(
//                 1,
//                 minter.address,
//                 to.address
//             );
//         });
//     });
// });