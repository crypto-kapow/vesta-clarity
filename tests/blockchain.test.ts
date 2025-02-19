
import { describe, expect, it } from "vitest";
import { Cl, cvToJSON, tupleCV } from '@stacks/transactions';

import {
  uintCV,
} from "@stacks/transactions";
import { cvToValue } from "@stacks/transactions/src/clarity/clarityValue.ts";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

describe("Test Block Info", () => {
  const start = simnet.callReadOnlyFn("blockchain", "get-mining-start-block", [], address1);
  const cvStartBlock = start.result;
  const initialBurnHeight = simnet.burnBlockHeight;

  expect(cvStartBlock).toBeUint(170);
  console.log(cvStartBlock);
  const iStartBlock = Number(cvToValue(cvStartBlock));

  it("can determine block 0 at launch", () => {
    console.log("Start Block: " + iStartBlock + ", initialBurnHeight: " + initialBurnHeight);

    let { result } = simnet.callReadOnlyFn("blockchain", "next-mining-block", [], address1);
    expect(result).toBeOk(Cl.tuple({height: Cl.uint(0), burnBlock: cvStartBlock}));
  });

  it("can detect the next few blocks", () => {
    // Move burn chain to right before first mining block
    console.log("Start Block: " + iStartBlock + ", initialBurnHeight: " + initialBurnHeight);

    simnet.mineEmptyBlocks(iStartBlock - initialBurnHeight - 1);
    console.log("1. Burn Block Height: " + simnet.burnBlockHeight);
    let resp = simnet.callReadOnlyFn("blockchain", "next-mining-block", [], address1);
    let result = resp.result;
    expect(result).toBeOk(Cl.tuple({ height: Cl.uint(0), burnBlock: uintCV(iStartBlock)}));

    // Block 1
    simnet.mineEmptyBlocks(1);
    console.log("2. Burn Block Height: " + simnet.burnBlockHeight);
    resp = simnet.callReadOnlyFn("blockchain", "next-mining-block", [], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.tuple({ height: Cl.uint(1), burnBlock: uintCV(iStartBlock + 6) }));

    // Block 1
    simnet.mineEmptyBlocks(1);
    console.log("3. Burn Block Height: " + simnet.burnBlockHeight);
    resp = simnet.callReadOnlyFn("blockchain", "next-mining-block", [], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.tuple({ height: Cl.uint(1), burnBlock: uintCV(iStartBlock + 6) }));

    // Block 1
    simnet.mineEmptyBlocks(4);
    console.log("4. Burn Block Height: " + simnet.burnBlockHeight);
    resp = simnet.callReadOnlyFn("blockchain", "next-mining-block", [], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.tuple({ height: Cl.uint(1), burnBlock: uintCV(iStartBlock + 6) }));

    // Block 2
    simnet.mineEmptyBlocks(1);
    console.log("5. Burn Block Height: " + simnet.burnBlockHeight);
    resp = simnet.callReadOnlyFn("blockchain", "next-mining-block", [], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.tuple({ height: Cl.uint(2), burnBlock: uintCV(iStartBlock + 12) }));

    // Block 2
    simnet.mineEmptyBlocks(5);
    console.log("6. Burn Block Height: " + simnet.burnBlockHeight);
    resp = simnet.callReadOnlyFn("blockchain", "next-mining-block", [], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.tuple({ height: Cl.uint(2), burnBlock: uintCV(iStartBlock + 12) }));

    // Block 3
    simnet.mineEmptyBlocks(1);
    console.log("7. Burn Block Height: " + simnet.burnBlockHeight);
    resp = simnet.callReadOnlyFn("blockchain", "next-mining-block", [], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.tuple({ height: Cl.uint(3), burnBlock: uintCV(iStartBlock + 18) }));

  })

  it("can return the burn height for blocks", () => {
    console.log("Start Block: " + iStartBlock + ", initialBurnHeight: " + initialBurnHeight);

    let resp = simnet.callReadOnlyFn("blockchain", "burn-height-for-block", [uintCV(0)], address1);
    let result = resp.result;
    expect(result).toBeOk(Cl.uint(iStartBlock));

    resp = simnet.callReadOnlyFn("blockchain", "burn-height-for-block", [uintCV(1)], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.uint(iStartBlock + 6));

    resp = simnet.callReadOnlyFn("blockchain", "burn-height-for-block", [uintCV(102)], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.uint(iStartBlock + (102 * 6)));
  })

  it("can return if blocks are in the future", () => {
    console.log("Start Block: " + iStartBlock + ", initialBurnHeight: " + initialBurnHeight);

    let resp = simnet.callReadOnlyFn("blockchain", "is-future-block", [uintCV(0)], address1);
    let result = resp.result;
    expect(result).toBeOk(Cl.bool(true));

    resp = simnet.callReadOnlyFn("blockchain", "is-future-block", [uintCV(3)], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.bool(true));

    simnet.mineEmptyBlocks(iStartBlock - initialBurnHeight - 1);
    resp = simnet.callReadOnlyFn("blockchain", "is-future-block", [uintCV(0)], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.bool(true));

    simnet.mineEmptyBlocks(1);
    resp = simnet.callReadOnlyFn("blockchain", "is-future-block", [uintCV(0)], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.bool(true));

    simnet.mineEmptyBlocks(1);
    resp = simnet.callReadOnlyFn("blockchain", "is-future-block", [uintCV(0)], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.bool(false));

    simnet.mineEmptyBlocks(5);
    resp = simnet.callReadOnlyFn("blockchain", "is-future-block", [uintCV(1)], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.bool(true));

    simnet.mineEmptyBlocks(1);
    resp = simnet.callReadOnlyFn("blockchain", "is-future-block", [uintCV(1)], address1);
    result = resp.result;
    expect(result).toBeOk(Cl.bool(false));
  })


  // it("shows an example", () => {
  //   const { result } = simnet.callReadOnlyFn("counter", "get-counter", [], address1);
  //   expect(result).toBeUint(0);
  // });
});
