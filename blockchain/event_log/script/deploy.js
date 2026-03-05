async function main() {
  const AppEventLog = await ethers.getContractFactory("AppEventLog");

  // v6 style: deploy and wait until mined
  const contract = await AppEventLog.deploy();
  await contract.waitForDeployment();

  console.log("✅ Contract deployed at:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
