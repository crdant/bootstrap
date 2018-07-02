# PCF Bootstrap Environment

Bootstrap an environment with BOSH, secrets management ([Hashicorp
Vault](https://www.vaultproject.io)), [Concourse](https://concourse-ci.org), and
[PCF](https://pivotal.io). PCF is installed with the [PCF
Pipelines](https://github.com/pivotal-cf/pcf-pipelines). Uses [BOSH Boot
Loader](https://github.com/cloudfoundrb-bootloader) plan patches to simplify
setup. Currently working with AWS and GCP.

## Steps

1. Assure dependencies are met (see below)
1. If using GCP, enable the appropriate APIs.
1. Edit `lib/env.sh` to match your needs.
1. Run `prepare` to prepare infrastructure and the bootstrap BOSH environment
1. Make sure DNS for your bootstrap subdomain is delegated from your primary zone (if needed).
1. Run `secrets` to make Vault available for secrets.
1. Configure `secrets` for the bootstrap environment by running `configure`.
1. Add concourse to the environment with `concourse`.
1. (optional) Add LDAP to the environment with `ldap`.
1. Set the environment variable `PIVNET_TOKEN` to your Pivotal Network API token.
1. An SSH key in your `.ssh` directory named `concourse_github` with the public key registered with your Github account.
1. Add secrets under `concourse/pcf/deploy-pcf` path for your Google Cloud Storage
   S3-compatible access key id (`gcp_storage_access_key`) and secret access key (`gcp_storage_secret_key`) in vault.
1. Running `pcf` now will load [PCF Platform Automation with Concourse](https://network.pivotal.io/products/pcf-automation), nee [PCF Pipelines](https://github.com/pivotal-cf/pcf-pipelines), into the Concourse you just installed and trigger the right jobs to install PCF.

## Using the environment

All your connections to BOSH will be through SSH tunnels to the Jumpbox that the
BOSH Bootloader creates. To use the `bosh` CLI, make soure you source the file
`work/bbl-env.sh` into your shell with `. work/bbl-env.sh`, which will set up
the proxy that BOSH uses. If the tunnels times out, you can recreate it with
`prepare client login`.

LDAP, Vault, Concourse, and PCF have load balancers. You can access them at the
expected URIs based on your configuration. The PCF Pipelines are available in
the concourse team `pcf`, with username `pivotal`. To get the password run
`pcf secret concourse`

## Getting rid of the environment

Each of the scripts has a `teardown` command-line argument (except `prepare`). Run those, then run `teardown`.

1. Teardown PCF (`pcf teardown`).
2. If you added LDAP, remove it from the environment with `ldap teardown`.
3. Take down concourse with `concourse teardown`.
4. Get rid of Vault with `secrets teardown`.
5. Lastly, take down the infrastructure with `teardown`.

## Ergonomics

Each command has some subcommands for running a piece of what it does. More to come on that later.

## Dependencies

1. [BOSH Boot Loader](https://github.com/cloudfoundrb-bootloader) 6.x or later. It's in the Cloud Foundry tap on
Homebrew, so Mac users can run `brew install cloudfoundry/tap/bbl`.
2. [Safe](https://github.com/starkandwayne/safe). On a Mac you can run `brew install starkandwayne/cf/safe`.
3. Hashicorp [Vault CLI](https://www.vaultproject.io). If you're on a Mac run `brew install vault`.
4. The [Pivotal Network](https://network.pivotal.io) CLI, [`pivnet`](https://github.com/pivotal-cf/pivnet-cli). Again, with Homebrew `brew install pivotal/tap/pivotal-cli`.
5. [Certbot](https://github.com/certbot/certbot) to get certificates from Let's Encrypt. Install with `brew install certbot`.

## Coming soon

1. Deploy concourse with standard manifest plus ops files from [concourse-deployment](https://github.com/concourse/concourse-deployment)
1. ~~Make cloud config changes idempotent.~~
1. Use Credhub (created by `bbl` or standalone) instead of deploying/managing vault.
1. Windows in PCF and concourse
1. PCF tile support
1. Split working directory from script directory to simplify having local changes
1. Simple script(s) to do the manual stuff more easily.
1. Forcing and/or testing without SSH multiplexing. I use it all the time, colleagues who don't are seeing some weirdness.
1. Making this document more readable and useful.
1. Making secrets highly available.
1. Making LDAP highly available.
1. Other IaaSes. ~~AWS~~
1. Rewrite in a programming language for better modularity and invocation across modules
