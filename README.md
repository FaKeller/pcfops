# pcfops

pcfops is a concourse.io automation for operating Pivotal Cloud Foundry built on top of [pivotal-cf/pcf-pipelines](https://github.com/pivotal-cf/pcf-pipelines).
It has been designed from the ground up to operate staged Cloud Foundry installations, being able to keep multiple Cloud Foundry foundations in sync and giving operators a good night's sleep.


## Features

- Build a single, staged pipeline operating multiple CF foundations (e.g., going from a `test` to a `qa` to a `prod` foundation)
- Keep the pipelines and credentials separate
- Have first-class support for various Cloud Foundry related Pivotal tiles
- Simplifies pipeline customizations


> **Active Development:** This project is under active development. 
> Things may change today or tomorrow. In case you like the project, get involved to shape the future! :-)


## Concepts

### Configuration Conventions

A pipeline is built by composing various configuration files with [spruce](https://github.com/geofffranks/spruce) to the resulting pipeline.
For every product, a pipeline is built from configuration files in the following order from the following places (for each stage):

1. **Default configuration:** Setup pipeline with pcfops provided templates:
    1. Start with a [base template](/pipelines/upgrade-tile/stage-template.yml) provided by pcfops:  
      `pcfops/pipelines/upgrade-tile/stage-template.yml`
    1. Merge a product template provided by pcfops:  
      `pcfops/products/<PRODUCT>.yml`
1. **Product configuration:** Merge user product configuration
    1. Merge user-provided stage configuration. For example, this could setup resource locations.  
      `config/<PRODUCT>/common-<STAGE>.yml`
    1. Merge user-provided product configuration. Can be used to configure products across all stages.  
      `config/<PRODUCT>/<PRODUCT>.yml`
    1. Merge user-provided stage-specific product configuration. Can be used to refine products on a per-stage basis (e.g. allow/deny SSH access on dev/prod stages).  
      `config/<PRODUCT>/<PRODUCT>-<STAGE>.yml`
1. **Credentials configuration:** Merge user-provided credentials.
    1. Merge user-provided stage-specific credentials. These include API keys to access certain resources.  
      `credentials/common-<STAGE>.yml`
    1. Merge user-provided product-specific credentials. These might include passwords or certificates for a specific product in a specific stage.  
      `credentials/<PRODUCT>-<STAGE>.yml`


This procedure is repeated for every stage and the resulting jobs are concatenated to build the resulting pipeline.

> Note: missing configuration files are ignored as long as all required parameters are configured throughout the process.


## Getting Started

This repository contains a folder with a sample configuration for operating a multi-stage Pivotal Cloud Foundry installation.
You may have a look at the [/example-foundation](example source code) to see what you need to get started.

To get started, tailor the [`pcfops.yml`](/example-foundation/pcfops.yml) pipeline to your needs and add it to your concourse instance.
The pipeline takes care of creating all pipelines required to operate your Pivotal Cloud Foundry instance based on the configuration files supplied.


## pcfops vs. pcf-pipelines

Oh no, why yet another CF pipelines project?! The pcf-pipelines project does an awesome job at supplying highly-reusable concourse tasks to operate Pivotal Cloud Foundry.
However, the tasks do need to be glued together in a pipeline and the pipelines shipped with pcf-pipelines are inherently limited in their customizability and reusability.
This project was then born out of the need to operate staged Cloud Foundry installations with customizable pipelines and hence, merely focuses on building pipelines with the tasks provided by pcf-pipelines.


## Contributing

Open a PR :-)


## [Change Log](CHANGELOG.md)

See all changes made to this project in the [change log](CHANGELOG.md). This project follows [semantic versioning](http://semver.org/).
