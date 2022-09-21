const throwCatch = require('./helper/throw.js');

const MetaProfile = artifacts.require("MetaProfile");


contract("MetaProfile", function (accounts) {
  const owner = accounts[0];
  
  it("It should change the token base uri by owner", async function () {
    let mp = await MetaProfile.deployed();
    
    // Setup accounts.
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];
    
    await await mp.mint({from: account1});

    let token_id = 1;
    old_token1_uri = await mp.tokenURI(token_id);

    // Fail to set base uri
    let baseURI = "https://new.com/"
    await throwCatch.expectRevert(
      mp.setBaseURI(baseURI, {from: account1})
    );

    // Succeed in setting base uri
    await mp.setBaseURI(baseURI, {from: owner})
    
    new_token1_uri = await mp.tokenURI(token_id);
    console.log(new_token1_uri)
    assert.equal(new_token1_uri, "https://new.com/1", "URI of Token "+token_id+" should change to new address");
  });
});