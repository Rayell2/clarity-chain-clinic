import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Patient can initialize their records",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const result = chain.mineBlock([
      Tx.contractCall("patient-records", "initialize-patient", [], deployer.address)
    ]).receipts[0].result;
    
    assertEquals(result, "(ok true)");
  },
});

Clarinet.test({
  name: "Patient can authorize provider",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const provider = accounts.get("wallet_1")!;
    
    chain.mineBlock([
      Tx.contractCall("patient-records", "initialize-patient", [], deployer.address)
    ]);

    const auth = chain.mineBlock([
      Tx.contractCall("patient-records", "authorize-provider", 
        [types.principal(provider.address)], 
        deployer.address
      )
    ]).receipts[0].result;

    assertEquals(auth, "(ok true)");
  },
});
