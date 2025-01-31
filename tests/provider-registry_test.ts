import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Provider can register",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const provider = accounts.get("wallet_1")!;
    const result = chain.mineBlock([
      Tx.contractCall("provider-registry", "register-provider",
        [types.utf8("Test Provider"), types.ascii("LICENSE123")],
        provider.address
      )
    ]).receipts[0].result;
    
    assertEquals(result, "(ok true)");
  },
});

Clarinet.test({
  name: "Only owner can deactivate provider",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const provider = accounts.get("wallet_1")!;

    chain.mineBlock([
      Tx.contractCall("provider-registry", "register-provider",
        [types.utf8("Test Provider"), types.ascii("LICENSE123")],
        provider.address
      )
    ]);

    const result = chain.mineBlock([
      Tx.contractCall("provider-registry", "deactivate-provider",
        [types.principal(provider.address)],
        deployer.address
      )
    ]).receipts[0].result;

    assertEquals(result, "(ok true)");
  },
});
