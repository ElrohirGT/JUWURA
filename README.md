# JUWURA
[![DB Linting](https://github.com/ElrohirGT/JUWURA/actions/workflows/db.yml/badge.svg)](https://github.com/ElrohirGT/JUWURA/actions/workflows/db.yml)
[![Backend Lint and Tests](https://github.com/ElrohirGT/JUWURA/actions/workflows/backend.yml/badge.svg)](https://github.com/ElrohirGT/JUWURA/actions/workflows/backend.yml)
[![Frontend Lint and Tests](https://github.com/ElrohirGT/JUWURA/actions/workflows/frontend.yml/badge.svg)](https://github.com/ElrohirGT/JUWURA/actions/workflows/frontend.yml)

Jira but with anime and better UX!

# Development

This project uses Nix to develop! Please remember to install [Nix](https://nixos.org/) and to enable [Flakes](https://nixos.wiki/wiki/Flakes).

Please make sure you're on the root directory before executing any of the commands below.

To enter into a shell with all the necessary dependencies to develop JUWURA use the command:

```bash
nix develop
```

To start a development session with the backend, frontend and DB initialized from scratch use the command:

```bash
# Please make sure you're on the root directory of the repository.
# You don't need to run nix develop before running this command.
nix run .#restartServices
```

Each project has a `process.nix` file. This file exposes some attributes used for creating the dev environment lifted up by the command above.
You can find the postgresHost and postgresPort on the relevant `process.nix` file inside th database directory.
