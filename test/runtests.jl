using Test
using ZarrDatasets

@testset "ZarrDatasets.jl" begin
    include("test_cdm.jl")
    include("test_multifile.jl")
    include("test_write.jl")
end
