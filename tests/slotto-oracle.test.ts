
import { describe, expect, it } from "vitest";
import {Cl } from '@stacks/transactions';

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

describe("No price set", () => {
  it("ensures simnet is well initalised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("No price set for block 0", () => {
     const { result } = simnet.callReadOnlyFn("slotto-oracle", "get-price-at-height", [Cl.uint(0)], address1);
     expect(result).toBeOk(Cl.tuple({ price: Cl.uint(0), updates: Cl.uint(0) }));
  });

  it("No price set for block 100", () => {
    const { result } = simnet.callReadOnlyFn("slotto-oracle", "get-price-at-height", [Cl.uint(100)], address1);
    expect(result).toBeOk(Cl.tuple({ price: Cl.uint(0), updates: Cl.uint(0) }));
  });

});

