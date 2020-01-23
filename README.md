# Azure :: Landing Zone :: Hub-Spoke :: Terraform Modules

This repo contains `Terraform` modules for building a multi-region Hub-Spoke infrastructure in Azure that supports the Landing Zone architectural pattern.

## Usage

Modules could be used in your `Terraform` code by referencing this repo in the `module` block the following way:

```hcl
module "resource_groups" {
  source = "github.com/undp/tf-modules//azure_landing_zone/rg_for_each_location?ref=v0.1.0"

  locations  = [
    "northeurope",
    "westeurope"
  ]

  name_prefix = "app"

  namespace = "dev"

  tags = {
    Owner = "App Team"
  }
}
```

### Requirements

All modules have [`common.tf` symlink to the single file][CommonTfRef] defining the following requirements for the version of Terraform and Azure provider.

* Terraform >= 0.12
* Azure provider = 1.39

It is also expected that `Terraform` state is stored using `azurerm` backend. It is advised to use a tool like [Terragrunt][TerragruntRef] to manage state storage compartmentalization.

[CommonTfRef]: azure_landing_zone/common.tf
[TerragruntRef]: https://github.com/gruntwork-io/terragrunt

## Versioning

We use [Semantic Versioning Specification][SemVer] as a version numbering convention.

[SemVer]: http://semver.org/

## Release History

For the available versions, see the [tags on this repository][RepoTags]. Specific changes for each version are documented in [CHANGELOG.md][ChangelogRef].

Also, conventions for `git commit` messages are documented in [CONTRIBUTING.md][ContribRef].

[RepoTags]: https://github.com/undp/tf-modules/tags
[ChangelogRef]: CHANGELOG.md
[ContribRef]: CONTRIBUTING.md

## Authors

* **Oleksiy Kuzmenko** - [OK-UNDP@GitHub][OK-UNDP@GitHub] - *Initial design and implementation*

[OK-UNDP@GitHub]: https://github.com/OK-UNDP

## Acknowledgments

* Hat tip to all individuals shaping this project by sharing their knowledge in articles, blogs and forums.

## License

Unless otherwise stated, all authors (see commit logs) release their work under the [MIT License][MITRef]. See [LICENSE.md][LicenseRef] for details.

[LicenseRef]: LICENSE.md
[MITRef]: https://opensource.org/licenses/MIT

## Contributing

There are plenty of ways you could contribute to this project. Feel free to:

* submit bug reports and feature requests
* outline, fix and expand documentation
* peer-review bug reports and pull requests
* implement new features or fix bugs

See [CONTRIBUTING.md][ContribRef] for details on code formatting, linting and testing frameworks used by this project.
