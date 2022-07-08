const throwCatch = require('./helper/throw.js');

const MetaProfile = artifacts.require("MetaProfile");


contract("MetaProfile", function (accounts) {
  it("it should mint 3 new NFTs", async function () {
    let mp = await MetaProfile.deployed();
    
    // Setup owner
    owner = accounts[0];

    // Setup accounts.
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];

    // Try to mint a NFT to account1
    await mp.mint(true, {from: account1});
    const account1_nft_num = (await mp.balanceOf(account1)).toNumber();
    assert.equal(account1_nft_num, 1, "It doesn't mint 1 NFT of "+account1);
    let token_id = 1;
    assert.equal(await mp.isAllowedForSublease(token_id), true, "token:"+token_id+" should be set true");
  
    // Try to mint 2 NFTs to account2
    await mp.mint(false, {from: account2});
    const account2_nft_num = (await mp.balanceOf(account2)).toNumber();
    assert.equal(account2_nft_num, 1, "It doesn't mint 1 NFT of "+account2);
    token_id = 2;
    assert.equal(await mp.isAllowedForSublease(token_id), false, "token:"+token_id+" should be set false");

    // Try to mint a NFT to account3
    await mp.mint(true, {from: account3});
    const account3_nft_num = (await mp.balanceOf(account3)).toNumber();
    assert.equal(account3_nft_num, 1, "It doesn't mint 1 NFT of "+account3);
    token_id = 3;
    assert.equal(await mp.isAllowedForSublease(token_id), true, "token:"+token_id+" should be set true");

    // Check the contract state
    const totalSupply = (await mp.totalSupply()).toNumber();
    assert.equal(totalSupply, 3, "It doesn't have 3 NFTs totally");
  });

  it("it should burn 3 NFTs", async function () {
    let mp = await MetaProfile.deployed();
    
    // Setup owner
    owner = accounts[0];

    // Setup accounts.
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];

    // Try to burn the NFT of account1
    let token_id = 1;
    await mp.burn(token_id, {from: account1});
    const account1_nft_num = (await mp.balanceOf(account1)).toNumber();
    assert.equal(account1_nft_num, 0, "It should have 0 NFT of "+account1);
    await throwCatch.expectRevert ( 
      mp.isAllowedForSublease(token_id)
    )

    // Try to burn the NFT of account2
    token_id = 2;
    await throwCatch.expectRevert (
      mp.burn(token_id, {from: account1})
    )
    await mp.burn(token_id, {from: account2});
    const account2_nft_num = (await mp.balanceOf(account2)).toNumber();
    assert.equal(account2_nft_num, 0, "It should have 0 NFT of "+account2);

    // Try to burn the NFT of account3
    token_id = 3;
    await mp.burn(token_id, {from: account3});
    const account3_nft_num = (await mp.balanceOf(account3)).toNumber();
    assert.equal(account3_nft_num, 0, "It should have 0 NFT of "+account3);

    // Check the contract state
    const totalSupply = (await mp.totalSupply()).toNumber();
    assert.equal(totalSupply, 0, "It should have 0 NFT totally");
  });
});
