import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Provider can register with contact info",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const provider = accounts.get("wallet_1")!;
    const result = chain.mineBlock([
      Tx.contractCall("provider-registry", "register-provider",
        [
          types.utf8("Test Provider"),
          types.ascii("LICENSE123"),
          types.utf8("contact@provider.com")
        ],
        provider.address
      )
    ]).receipts[0].result;
    
    assertEquals(result, "(ok true)");
  },
});

Clarinet.test({
  name: "Users can rate providers",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const provider = accounts.get("wallet_1")!;
    const user = accounts.get("wallet_2")!;

    chain.mineBlock([
      Tx.contractCall("provider-registry", "register-provider",
        [
          types.utf8("Test Provider"),
          types.ascii("LICENSE123"),
          types.utf8("contact@provider.com")
        ],
        provider.address
      )
    ]);

    const ratingResult = chain.mineBlock([
      Tx.contractCall("provider-registry", "rate-provider",
        [
          types.principal(provider.address),
          types.uint(5)
        ],
        user.address
      )
    ]).receipts[0].result;

    assertEquals(ratingResult, "(ok true)");
  },
});

// [Previous tests remain unchanged]
