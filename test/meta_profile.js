const MetaProfile = artifacts.require("MetaProfile");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("MetaProfile", function (accounts) {
  it("it should mint 3 new NFT", async function () {
    let mp = await MetaProfile.deployed();
    
    // Setup owner
    owner = accounts[0];

    // Setup 3 accounts.
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];

    await mp.mint(true, {from: account1})
    const account1_nft_num = (await mp.balanceOf(account1)).toNumber()
    assert.equal(account1_nft_num, 1, "It doesn't mint 1 NFT of "+account1);

    await mp.mint(false, {from: account2})
    try {
      await mp.mint(false, {from: account2});
      assert.fail("The transaction should have thrown an error");
    } catch (err) {
      assert.include(err.message, "revert", "The error message should contain 'revert'");
    }

    const account2_nft_num = (await mp.balanceOf(account2)).toNumber()
    assert.equal(account1_nft_num, 1, "It doesn't mint 1 NFT of "+account1);

    await mp.mint(true, {from: account3})
    const account3_nft_num = (await mp.balanceOf(account3)).toNumber()
    assert.equal(account1_nft_num, 1, "It doesn't mint 1 NFT of "+account1);

    const totalSupply = (await mp.totalSupply()).toNumber()
    assert.equal(totalSupply, 3, "It doesn't have 3 NFTs totally");
  });
});
