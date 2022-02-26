require("@nomiclabs/hardhat-waffle");
require('hardhat-contract-sizer');

task("accounts","Prints the list of accounts", async(taskArgs, hre) => {
	const accounts = await hre.ethers.getSigners();

	for(const account of accounts){
		console.log(account.address);
	}
});


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.7",
  settings: {
	optimizer: {
	  enabled: true,
	  runs:100,
	},
  },
  contractSizer: {
	alphaSort: true,
	disambiguatePaths: false,
	runOnCompile: true,
	strict: true,
  }
};
