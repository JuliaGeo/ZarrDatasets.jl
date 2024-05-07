using Test
using ZarrDatasets

@testset "ZarrDatasets.jl" begin
    include("test_cdm.jl")
    include("test_multifile.jl")
    include("test_write.jl")
    include("test_groups.jl")
    include("test_fillvalue.jl")
    include("test_aqua.jl")
end
