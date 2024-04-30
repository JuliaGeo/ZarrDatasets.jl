using Aqua
using ZarrDatasets


Aqua.test_ambiguities(ZarrDatasets)
# some internal ambiguities in DiskArray 0.3 probably fixed in 0.4
Aqua.test_all(ZarrDatasets, ambiguities = false)
