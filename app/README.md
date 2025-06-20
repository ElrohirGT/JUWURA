# JUWURA Application

This project uses Nix to manage it's dependencies, you can simply type:

```bash
nix develop
```

And Nix will install and configure all the dependencies to run this project.

## Tasks

### dev

Run the project in development mode, with auto reloading. Make sure to already
be on the shell that Nix provides.

```bash
gleam run -m lustre/dev start
```
