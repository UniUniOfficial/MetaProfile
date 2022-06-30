const MetaProfile = artifacts.require("MetaProfile");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("MetaProfile", function (/* accounts */) {
  it("should assert true", async function () {
    await MetaProfile.deployed();
    return assert.isTrue(true);
  });
});
