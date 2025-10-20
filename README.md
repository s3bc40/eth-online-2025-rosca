# ETHOnline 2025 Rosca

## Overview

Hackathon project around Rosca (Rotating Savings and Credit Association) built with Turborepo, Next.js, Envio and Foundry. The goal is to create a decentralized platform for managing Roscas using smart contracts. Basically we move the organizer role to a smart contract and allow users to create/join roscas, contribute funds, and withdraw their share when it's their turn. To avoid trust issues, we use a multisig wallet for the organizer role, SafeWallet for the multisig wallet.
This project is bootstrapped with [Turborepo](https://turborepo.com/), for easy monorepo management and high performance builds.

## Tech stack

- [Foundry](https://getfoundry.sh/) - Smart contract development framework
- [Pyth network](https://pyth.network/) - Real-time market data
- [Envio](https://envio.dev/) - Perfomant blockchain indexer
- [PaypalUSD](https://www.paypal.com/us/digital-wallet/manage-money/crypto/pyusd) - Paypal Stablecoin
- [Turborepo](https://turborepo.com/) - Monorepo management tool
- [Next.js](https://nextjs.org/) - React framework for building web applications
- [TypeScript](https://www.typescriptlang.org/) - Typed superset of JavaScript
- [RainbowKit](https://www.rainbowkit.com/) - React library for wallet connection
- [Wagmi](https://wagmi.sh/) - React hooks for Ethereum
- [Tailwind CSS](https://tailwindcss.com/) - Utility-first CSS framework
- [SafeWallet](https://safe.global/) - Multisig wallet for secure fund management

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (version 18 or later)
- [pnpm](https://pnpm.io/) (version 9 or later)
- [Foundry](https://getfoundry.sh/) (version 1.3.0 or later)
- [Docker](https://www.docker.com/) (for devcontainer and/or running Envio)

### Installation

When you first clone the repository, you have two ways to install dependencies:

1. Locally if you have the prerequisites installed and a UNIX-like environment (Linux, macOS, WSL2)
2. Using the [devcontainer](https://code.visualstudio.com/docs/devcontainers/containers) if you have Docker and VSCode installed (or any IDE that supports devcontainers)

#### Local Installation

When you have the prerequisites installed, run the following commands:

```bash
cd ethonline-2025-rosca
pnpm install
```

It should install all dependencies for the monorepo. You can then proceed to set up Envio by:

```bash
cd apps/envio-indexer
pnpm run codegen
```

Or run from the root:

```bash
pnpm run envio:codegen
```

This will generate the necessary packages and containers for Envio.

Then you can start the Envio indexer:

```bash
cd apps/envio-indexer
pnpm run dev

# or from the root
pnpm run envio:dev
```

If you manage to start the indexer, you can proceed to start the web app.

First setup the environment variables by copying the example file:

```bash
cd apps/web
cp .env.example .env.local
```

Set the necessary environment variables in `.env.local`, then start the web app:

```bash
pnpm run dev
```

#### Using the Devcontainer

If you have Docker and VSCode installed, you can open the project in a devcontainer. This will set up a container with all the necessary dependencies installed.

1. Open the project in VSCode
2. When prompted, reopen the project in a devcontainer or use the command palette (Ctrl+Shift+P) and select "Dev Containers: Reopen in Container"
3. Wait for the container to build and start (or use the command palette and select "Dev Containers: Rebuild Container" if you don't get prompted)
4. Once the container is running, you should be able to run the same commands as above to set up Envio and start the web app.

You should be ready to develop!

### Build

WIP

## Remote Caching

> [!TIP]
> Vercel Remote Cache is free for all plans. Get started today at [vercel.com](https://vercel.com/signup?/signup?utm_source=remote-cache-sdk&utm_campaign=free_remote_cache).

Turborepo can use a technique known as [Remote Caching](https://turborepo.com/docs/core-concepts/remote-caching) to share cache artifacts across machines, enabling you to share build caches with your team and CI/CD pipelines.

By default, Turborepo will cache locally. To enable Remote Caching you will need an account with Vercel. If you don't have an account you can [create one](https://vercel.com/signup?utm_source=turborepo-examples), then enter the following commands:

```bash
cd my-turborepo

# With [global `turbo`](https://turborepo.com/docs/getting-started/installation#global-installation) installed (recommended)
turbo login

# Without [global `turbo`](https://turborepo.com/docs/getting-started/installation#global-installation), use your package manager
npx turbo login
yarn exec turbo login
pnpm exec turbo login
```

This will authenticate the Turborepo CLI with your [Vercel account](https://vercel.com/docs/concepts/personal-accounts/overview).

Next, you can link your Turborepo to your Remote Cache by running the following command from the root of your Turborepo:

```bash
# With [global `turbo`](https://turborepo.com/docs/getting-started/installation#global-installation) installed (recommended)
turbo link

# Without [global `turbo`](https://turborepo.com/docs/getting-started/installation#global-installation), use your package manager
npx turbo link
yarn exec turbo link
pnpm exec turbo link
```

## Useful Links

Learn more about the power of Turborepo:

- [Tasks](https://turborepo.com/docs/crafting-your-repository/running-tasks)
- [Caching](https://turborepo.com/docs/crafting-your-repository/caching)
- [Remote Caching](https://turborepo.com/docs/core-concepts/remote-caching)
- [Filtering](https://turborepo.com/docs/crafting-your-repository/running-tasks#using-filters)
- [Configuration Options](https://turborepo.com/docs/reference/configuration)
- [CLI Usage](https://turborepo.com/docs/reference/command-line-reference)

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributors

Thanks to everyone who has contributed to ETHOnline 2025!

<a href="https://github.com/s3bc40/eth-online-2025-rosca/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=s3bc40/eth-online-2025-rosca" />
</a>
