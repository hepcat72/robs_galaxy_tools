# robs_galaxy_tools
Galaxy tool wrappers for bioinformatics tools.

I will be slowly adding tools over time.

## Current tool wrapper list

* svtyper - Annotate structural variants
* vcfSampleCompare - Sort and/or filter variants based on differences between sample groups
* lumpyexpress - Find structural variants

## Known Issues

There is a galaxy wrapper issue with lumpyexpress.  If you previously installed version 0.1.0 of the lumpyexpress wrapper, you may not be able to install the latest revision.  Galaxy will tell you that a new version is available (0.1.2), but when you try to update it, galaxy tells you you already have the latest version and does not update the wrapper, leaving the version unchanged.  To work around this issue and get the latest version (0.1.2), you must uninstall version 0.1.0 (and version 0.1.1, if you have it).  Re-installing will get you to the latest version.  Version 0.1.2 of the lumpyexpress wrapper works around a segfault issue with the latest version of lumpy/lumpyexpress (0.2.14a) where if a sample doesn't have enough paired-end coverage to calculate the insert size, the call to lumpy (which omits the corresponding discordant files) results in a segmentation fault and a core dump.  The galaxy wrapper works around this issue by modifying that coverage threshold in a copy of the lumpyexpress script (making it essentially revert to the behavior of an early revision of lumpy version 0.2.13).
