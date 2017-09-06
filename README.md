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
   S3-compatible access key id (`gcp_storage_access_key`) and secret access key (`gcp_storage_secret_key`) in vault.
1. Running the `pcf.sh` now will load [PCF Platform Automation with Concourse](https://network.pivotal.io/products/pcf-automation) (aka [PCF Pipelines]())

## Using the environment

All your connections to BOSH, Vault, and LDAP will be through SSH tunnels to the Jumpbox that the BOSH Bootloader creates. To use the `bosh` CLI,
make soure you source the file `work/bbl-env.sh` into your shell with `. work/bbl-env.sh`, which will set up the proxy that BOSH uses.
The Vault and LDAP processes will also setup tunnels for you, so you'll be working through the default ports on `localhost` for each
of those (8200 for Vault, 636 for LDA with SSL/TLS).  If the tunnels time out, you can recreate them with the sequence `./prepare.sh client login ; ./vault.sh tunnel ; ./ldap.sh tunnel`. *A convenience script for this is coming soon.*

Concourse and PCF have load balancers. You can access them at the expected URIs based on your configuration.

## Getting rid of the environment

Each of the scripts has a `teardown` command-line argument (except `prepare.sh`). Run those, then run `teardown.sh`.

1. Teardown PCF (`pcf.sh teardown`).
2. If you added LDAP, remove it from the environment with `ldap.sh teardown`.
3. Take down concourse with `concourse.sh teardown`.
4. Get rid of Vault with `vault.sh teardown`.
5. Lastly, take down the infrastructure with `teardown.sh`.

## Ergonomics

Each command has some subcommands for running a piece of what it does. More to come on that later.

## Dependencies

1. [BOSH Boot Loader](https://github.com/cloudfoundry/bosh-bootloader) 4.4 or later. It's in the Cloud Foundry tap on
Homebrew, so Mac users can run `brew install cloudfoundry/tap/bbl`.
2. [Safe](https://github.com/starkandwayne/safe). On a Mac you can run `brew install starkandwayne/cf/safe`.
3. Hashicorp [Vault CLI](https://www.vaultproject.io). If you're on a Mac run `brew install vault`.

## Coming soon

1. Forcing and/or testing without SSH multiplexing. I use it all the time, colleagues who don't are seeing some weirdness.
1. Making this document more readable and useful.
1. Making vault highly available.
1. Making LDAP highly available.
1. Other IaaSes.
