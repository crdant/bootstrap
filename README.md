# PCF Bootstrap Environment

Bootstrap an environment to do various BOSH-y things. Currently GCP specific.

## Steps

1. Assure dependencies are met (see below)
1. Edit `lib/env.sh` to match your needs.
1. Run `prepare.sh` to prepare GCP and the bootstrap BOSH environment
1. Run `vault.sh` to make Vault available for secrets.
1. Configure `vault` for the bootstrap environment by running `configure.sh`.
1. Add concourse to the environment with `concourse.sh`.
1. (optional) Add LDAP to the environment with `ldap.sh`.
1. Set the environment variable `PIVNET_TOKEN` to your Pivotal Network API token.
1. Add secrets under `concourse/pcf/deploy-pcf` path for your Google Cloud Storage
   S3-compatible access key id (`gcp_storage_access_key`) ans secret access key (`gcp_storage_secret_key`).
1. Prepare the PCF pipelines and install PCF with `pcf.sh`.

## Getting rid of the environment

Each of the scripts has a `teardown` command-line argument (except `prepare.sh`). Run those, then run `teardown.sh`.

## Ergonomics

Each command has some subcommands for running a piece of what it does. More to come on that later.

## Dependencies

1. [BOSH Boot Loader](https://github.com/cloudfoundry/bosh-bootloader) 4.4 or later.
2. [Safe](https://github.com/starkandwayne/safe)  
