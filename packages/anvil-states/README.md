# Anvil states package

Allow to store the dumped state of an Anvil node to speed up testing and development.

## Getting Started

To create an initial dumped state with Safe smart accounts, we linked our repo with a git submodule to [safe-smart-account](https://github.com/safe-global/safe-smart-account) at the specific commit of the v.1.4.1-3 release (commit: `21dc824`). This is only needed for development purposes, so you can skip this step if you don't plan to modify the Safe smart account contracts.

Initialize the git submodule:

```bash
git submodule update --init --recursive
```

## Development

The following steps takes credits from this Medium article: [How to deploy (Gnosis) Safe Multisig locally using anvil](https://medium.com/coinmonks/how-to-deploy-gnosis-safe-multisig-locally-using-anvil-d6d1da6fb198). Here are the steps we followed to create the dumped state:

1. Install dependencies in the `safe-smart-account` package:

```bash
cd packages/safe-smart-account
npm i
```

2. Compile the contracts with hardhat:

```bash
npm run build
```

3. Test the contracts to make sure everything is working:

```bash
npm run test
```

4. Start an Anvil node in a separate terminal:

```bash
# Adapt the path to your needs depending on where you start the anvil node
anvil --dump-state packages/anvil-states/anvil-safe-smart-accounts.json
```

5. Create a `.env` file in the `safe-smart-account` package with the following content:

```
MNEMONIC="test test test test test test test test test test test junk"
NODE_URL="http://127.0.0.1:8545"
```

6. Deploy the contracts to the Anvil node:

```bash
npx hardhat --network custom deploy
```

You should expect this output:

```bash
sending eth to create2 contract deployer address (0xE1CB04A0fA36DdD16a06ea828007E35e1a3cBC37) (tx: 0xbd7fc0fb4d864abc6b15e991b966fb54b5103e1ddfe1eddaee1c2ea93f277393)...
deploying create2 deployer contract (at 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7) using deterministic deployment (https://github.com/Arachnid/deterministic-deployment-proxy) (tx: 0x41a6b731f53cf45627c3976abcb9ecd52fb2142f8f6fbbff4e0bb54a9b3667bc)...
deploying "SimulateTxAccessor" (tx: 0x034754fc527e792395b2836a0ff9ac9afd0c7d6823a8022d2cc8d89e327fdbb0)...: deployed at 0x3d4BA2E0884aa488718476ca2FB8Efc291A46199 with 237931 gas
deploying "SafeProxyFactory" (tx: 0xb078c9345970d251793aa5e1ba2ceaf216d8a31fd2b8e8d6d686e5c3e152eda1)...: deployed at 0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67 with 712622 gas
deploying "TokenCallbackHandler" (tx: 0x518956b3356d4bac93c6863438f3663918b394828dc8132cce717605859d976f)...: deployed at 0xeDCF620325E82e3B9836eaaeFdc4283E99Dd7562 with 453406 gas
deploying "CompatibilityFallbackHandler" (tx: 0xdf263f48ce2c36f7c9a22a13fa1f0492f4c19fb46c359bfee2c40988111e1a02)...: deployed at 0xfd0732Dc9E303f09fCEf3a7388Ad10A83459Ec99 with 1270132 gas
deploying "CreateCall" (tx: 0x1f3b5efbe313975ee3b7512f3f9a11a8ce555c32beccaacd79017d3d4c64ad8b)...: deployed at 0x9b35Af71d77eaf8d7e40252370304687390A1A52 with 290470 gas
deploying "MultiSend" (tx: 0xab7a67482683979762e1832dbb55b449756944b3980dfe2bbc10afd5fd2cc7e6)...: deployed at 0x38869bf66a61cF6bDB996A6aE40D5853Fd43B526 with 190062 gas
deploying "MultiSendCallOnly" (tx: 0x5b49511fdd23d50269f34b0bf479bfec715cc3a4124993d07d4c9ffee4a4d895)...: deployed at 0x9641d764fc13c8B624c04430C7356C1C7C8102e2 with 142150 gas
deploying "SignMessageLib" (tx: 0xd5f0e18be1ed990a4d1c9125899c8f91ee2f7ed691e8fdc0d14f891dc79a61ed)...: deployed at 0xd53cd0aB83D845Ac265BE939c57F53AD838012c9 with 262417 gas
deploying "SafeToL2Setup" (tx: 0xdfd9a8356d4a90e801eeb9d299ff7b2eb285d6dc1c63bb4bc0d0f6327c885b54)...: deployed at 0xBD89A1CE4DDe368FFAB0eC35506eEcE0b1fFdc54 with 230863 gas
deploying "Safe" (tx: 0x293c91e6d6e5358019b8709d83dd8f0083e4bad31dd3c78dd719c19427456855)...: deployed at 0x41675C099F32341bf84BFc5382aF534df5C7461a with 5150072 gas
deploying "SafeL2" (tx: 0x8039880253378e77816b0e068ab0dbd24880e242796602aff6e835c1bd6de05a)...: deployed at 0x29fcB43b46531BcA003ddC8FCB67FFE91900C762 with 5332531 gas
deploying "SafeToL2Migration" (tx: 0x85ab3db174a57e8260187ae5933ba5f5a56c07e0c334497fbfdbc5fa94c8a508)...: deployed at 0xfF83F6335d8930cBad1c0D439A841f01888D9f69 with 1283078 gas
deploying "SafeMigration" (tx: 0x538bb1a445612fb5957bc182c1385c9b5fc66d345288995812e21c3629bc5c8c)...: deployed at 0x526643F69b81B008F46d95CD5ced5eC0edFFDaC6 with 512858 gas
```

7. Stop the Anvil node (Ctrl+C) and you should have the dumped state file at `packages/anvil-states/anvil-safe-smart-accounts.json`.

You can now use this dumped state file to start an Anvil node with the Safe smart accounts already deployed.

_Note: to extract the name of the deployed contracts and their addresses, we used AI to parse the output of the deployment script into `safe-contracts.json` file in this package._
