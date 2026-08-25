terraform {
  # Matches the module's own constraint.
  required_version = ">= 1.5.5"

  # DELIBERATELY no `required_providers` for proxmox. The module pins the
  # provider exactly, so a second exact pin here could only ever agree with it
  # by coincidence -- and disagreeing makes `terraform init` fail outright:
  #
  #   Error: Failed to query available provider packages
  #     no available releases match the given constraints
  #     3.0.2-rc07, 3.0.2-rc09
  #
  # That is not hypothetical: it took out every consumer of this module for a
  # week when a dependency bot bumped the root pin. See docs/provider-versions.md.
}
