const throwCatch = require('./helper/throw.js');

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
    const account4 = accounts[4];

    // Try to mint a NFT to account1
    await mp.mint(true, {from: account1});
    const account1_nft_num = (await mp.balanceOf(account1)).toNumber();
    assert.equal(account1_nft_num, 1, "It doesn't mint 1 NFT of "+account1);
    let token_id = 1;
    assert.equal(await mp.isAllowedForSublease(token_id), true, "token:"+token_id+" is set true");
  
    // Try to mint 2 NFTs to account2
    await mp.mint(false, {from: account2});
    await throwCatch.expectRevert (
      mp.mint(false, {from: account2})
    )
    const account2_nft_num = (await mp.balanceOf(account2)).toNumber();
    assert.equal(account2_nft_num, 1, "It doesn't mint 1 NFT of "+account2);
    token_id = 2;
    assert.equal(await mp.isAllowedForSublease(token_id), false, "token:"+token_id+" is set false");

    // Try to mint a NFT to account3
    await mp.mint(true, {from: account3});
    const account3_nft_num = (await mp.balanceOf(account3)).toNumber();
    assert.equal(account3_nft_num, 1, "It doesn't mint 1 NFT of "+account3);
    token_id = 3;
    assert.equal(await mp.isAllowedForSublease(token_id), true, "token:"+token_id+" is set true");

    const totalSupply = (await mp.totalSupply()).toNumber();
    assert.equal(totalSupply, 3, "It doesn't have 3 NFTs totally");
  });
});
