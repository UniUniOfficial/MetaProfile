const throwCatch = require('./helper/throw.js');
const timeHelper = require('./helper/time.js');

const MetaProfile = artifacts.require("MetaProfile");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("MetaProfile", function (accounts) {
  it("it should lease one NFT to two other addresses", async function () {
    let mp = await MetaProfile.deployed();
    
    // Setup owner
    owner = accounts[0];

    // Setup accounts.
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];
    const account4 = accounts[4];

    // Fail to Lease NFT
    await mp.mint(false, {from: account1});
    let token_id = 1;
    let expires = timeHelper.getTimestampInSeconds() + 3600;
    await throwCatch.expectRevert(
      mp.lease(token_id, account2, expires)
    );

    // Lease NFT
    await mp.lease(token_id, account2, expires, {from: account1});
    let expectExpires = (await mp.leaseExpiresOf(token_id, account2)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" lease of " + account2 + " should be expired at "+expires);
    
    await mp.lease(token_id, account3, expires, {from: account1});
    expectExpires = (await mp.leaseExpiresOf(token_id, account3)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" lease of " + account3 + " should be expired at "+expires);
  
    // Check lease state
    expectExpires = (await mp.leaseExpiresOf(token_id)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" lease should be expired at "+expires);

    // Extend expires
    expires = expires + 3600;
    await mp.lease(token_id, account2, expires, {from: account1});
    expectExpires = (await mp.leaseExpiresOf(token_id, account2)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" lease of " + account2 + " should be expired at "+expires);

    // Check lease state
    expectExpires = (await mp.leaseExpiresOf(token_id)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" lease should be expired at "+expires);
  
    // lease NFT
    expires = expires + 3600;
    await mp.lease(token_id, account4, expires, {from: account1});
    expectExpires = (await mp.leaseExpiresOf(token_id)).toNumber()
    assert.equal(expectExpires, expires, "the token:"+token_id+" lease should be expired at "+expires);
  });

  it("it shouldn't be burned when there is a ongoing lease", async function () {
    let mp = await MetaProfile.deployed();
    
    // Setup owner
    owner = accounts[0];

    // Setup accounts.
    const account1 = accounts[1];
    const account2 = accounts[2];

    // Fail to burn
    await mp.mint(false, {from: account1});
    let token_id = 2;
    let expires = timeHelper.getTimestampInSeconds() + 3600;
    await mp.lease(token_id, account2, expires, {from: account1});
    await throwCatch.expectRevert(
      mp.burn(token_id, {from: account1})
    );
    
    // burn after expires
    await mp.mint(false, {from: account1});
    token_id = 3;
    expires = timeHelper.getTimestampInSeconds() + 2;
    await mp.lease(token_id, account2, expires, {from: account1});
    await timeHelper.timeout(3000);
    await mp.burn(token_id, {from: account1})
  });

});
