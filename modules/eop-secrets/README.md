# Description

> This module must be applied and secrets manager values populated before terraform creates modules that use these
> secrets.

This module contains the configuration of the meta-data for secrets used in EOP.
This explicitly doesn't contain secret values, and those need to be created manually.
What this does mean is that dependencies between modules and secrets can be represented in code rather than via
hard-coded strings.

This could be thought of an antipattern that this module contains secrets' definitions from many potentially
unrelated modules. However, we're accepting this vs having to create many small modules for config.


 
