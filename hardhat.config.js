require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/9e4ac0275a2f45afbd9667945abe4590",
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    }
  },
  solidity: "0.8.19",
};
