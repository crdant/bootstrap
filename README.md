# PCF Bootstrap Environment

Bootstrap an environment to do various BOSH-y things. Currently GCP specific.

## Steps

1. Assure dependencies are met (see below)
1. Enable the APIs for google.
1. Edit `lib/env.sh` to match your needs.
1. Run `prepare.sh` to prepare GCP and the bootstrap BOSH environment
1. Make sure DNS for your bootstrap subdomain is delegated from your primary zone (if needed).
1. Run `vault.sh` to make Vault available for secrets.
1. Configure `vault` for the bootstrap environment by running `configure.sh`.
1. Add concourse to the environment with `concourse.sh`.
1. (optional) Add LDAP to the environment with `ldap.sh`.
1. Set the environment variable `PIVNET_TOKEN` to your Pivotal Network API token.
1. Add secrets under `concourse/pcf/deploy-pcf` path for your Google Cloud Storage
   S3-compatible access key id (`gcp_storage_access_key`) ans secret access key (`gcp_storage_secret_key`).
1. Prepare the PCF pipelines and install PCF with `pcf.sh`.

## Using the environment

All your connections will be through SSH tunnels to the Jumpbox that the BOSH Bootloader creates. To use the `bosh` CLI,
make soure you source the file `work/bbl-env.sh` into your shell with `. work/bbl-env.sh`, which will set up the proxy that BOSH uses.
The Vault and LDAP processes will also setup tunnels for you, so you'll be working through the default ports on `localhost` for each
of those (8200 for Vault, 636 for LDA with SSL/TLS).

If the tunnels time out, you can recreate them with the sequence `./prepare.sh client login ; ./vault.sh tunnel ; ./ldap.sh tunnel`.
A convenience script for this is coming soon.

## Getting rid of the environment

Each of the scripts has a `teardown` command-line argument (except `prepare.sh`). Run those, then run `teardown.sh`.

## Ergonomics

Each command has some subcommands for running a piece of what it does. More to come on that later.

## Dependencies

1. [BOSH Boot Loader](https://github.com/cloudfoundry/bosh-bootloader) 4.4 or later.
2. [Safe](https://github.com/starkandwayne/safe)  
