// scripts/deploy.js

//npx hardhat run scripts/deployP2P.js --network sepolia

const hre = require("hardhat");

async function main() {
  const AssigmentP2P = await hre.ethers.getContractFactory("AssigmentP2P");
  const assigmentP2P = await AssigmentP2P.deploy();

  await assigmentP2P.waitForDeployment();

  console.log("AssignmentP2P deployed to:", assigmentP2P.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });