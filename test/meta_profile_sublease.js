const throwCatch = require('./helper/throw.js');
const timeHelper = require('./helper/time.js');

const MetaProfile = artifacts.require("MetaProfile");


contract("MetaProfile", function (accounts) {
  it("it should sublease the NFT to one other address", async function () {
    let mp = await MetaProfile.deployed();
    
    // Setup owner
    owner = accounts[0];

    // Setup accounts.
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];
    const account4 = accounts[4];

    // Sublease the NFT
    await mp.mint(true, {from: account1});
    let token_id = 1;
    let expires = timeHelper.getTimestampInSeconds() + 3600;
    await mp.lease(token_id, account2, expires, {from: account1});
    await mp.sublease(token_id, account2, account3, {from: account2})
    
    // Check the lease
    expectExpires = (await mp.leaseExpiresOf(token_id, account3)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" lease of " + account2 + " should be transfered to "+account3);
    expectExpires = (await mp.leaseExpiresOf(token_id, account2)).toNumber()
    assert.equal(expectExpires, 0, "the token:"+token_id+" lease of " + account2 + " should be removed");

    // Fail to sublease twice
    await throwCatch.expectRevert(
      mp.sublease(token_id, account2, account3, {from: account2})
    );

    // Sublease again
    await mp.sublease(token_id, account3, account4, {from: account3})
    expectExpires = (await mp.leaseExpiresOf(token_id, account4)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" lease of " + account3 + " should be transfered to "+account4);
    expectExpires = (await mp.leaseExpiresOf(token_id, account3)).toNumber()
    assert.equal(expectExpires, 0, "the token:"+token_id+" lease of " + account3 + " should be removed");

    // Check the state
    expectExpires = (await mp.leaseExpiresOf(token_id)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" should have a ongoing lease at least");
    assert.equal(expectExpires > timeHelper.getTimestampInSeconds(), true, "the token:"+token_id+" should have a ongoing lease at least");
  });

  it("it should fail to sublease the NFT", async function () {
    let mp = await MetaProfile.deployed();
    
    // Setup owner
    owner = accounts[0];

    // Setup accounts.
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];
    const account4 = accounts[4];

    // Fail to sublease NFT without allowance
    await mp.mint(false, {from: account1});
    let token_id = 2;
    let expires = timeHelper.getTimestampInSeconds() + 3600;
    await mp.lease(token_id, account2, expires, {from: account1});

    await throwCatch.expectRevert(
      mp.sublease(token_id, account2, account3)
    );

    // Fail to sublease NFT after lease is due
    await mp.mint(true, {from: account1});
    token_id = 3;
    expires = timeHelper.getTimestampInSeconds() + 2;
    await mp.lease(token_id, account2, expires, {from: account1});
    await timeHelper.timelapse(3000)
    expectExpires = (await mp.leaseExpiresOf(token_id, account2)).toNumber()
    now = timeHelper.getTimestampInSeconds()
    assert.equal(expectExpires < now, true, "the token:"+token_id+" lease of " + account2 + " should be expired now");
    await throwCatch.expectRevert(
      mp.sublease(token_id, account2, account3, {from: account2})
    )
  });

  it("it should sublease the NFT after approved to other address", async function () {
    let mp = await MetaProfile.deployed();
    
    // Setup owner
    owner = accounts[0];

    // Setup accounts.
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];
    const exchange = accounts[4];

    // Approved and lease the NFT
    await mp.mint(true, {from: account1});
    let token_id = 4;
    let expires = timeHelper.getTimestampInSeconds() + 3600;
    await mp.setApprovalForAll(exchange, true, {from: account1});
    await mp.lease(token_id, account2, expires, {from: exchange});

    // Withdraw and Fail to lease the NFT
    await mp.setApprovalForAll(exchange, false, {from: account1});
    await throwCatch.expectRevert(
      mp.lease(token_id, account3, expires, {from: exchange})
    )

    // Approved and sublease the NFT
    await mp.setApprovalForAll(exchange, true, {from: account1});
    await mp.sublease(token_id, account2, account3, {from: exchange});

    // Withdraw and Fail to sublease the NFT
    await mp.setApprovalForAll(exchange, false, {from: account1});
    await throwCatch.expectRevert(
      mp.sublease(token_id, account3, account2, {from: exchange})
    );

    expectExpires = (await mp.leaseExpiresOf(token_id, account3)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" lease of " + account2 + " should be transfered to "+account3);
    expectExpires = (await mp.leaseExpiresOf(token_id, account2)).toNumber()
    assert.equal(expectExpires, 0, "the token:"+token_id+" lease of " + account2 + " should be removed");

    // Check the state
    expectExpires = (await mp.leaseExpiresOf(token_id)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" should have a ongoing lease at least");
    assert.equal(expectExpires > timeHelper.getTimestampInSeconds(), true, "the token:"+token_id+" should have a ongoing lease at least");
  });
});
