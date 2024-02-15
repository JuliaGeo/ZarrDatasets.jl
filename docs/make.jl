using Documenter: Documenter, makedocs, deploydocs
using ZarrDatasets: ZarrDatasets

makedocs(;
    modules=[ZarrDatasets],
    repo="https://github.com/JuliaGeo/ZarrDatasets.jl/blob/{commit}{path}#{line}",
    sitename="ZarrDatasets.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliageo.github.io/ZarrDatasets.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGeo/ZarrDatasets.jl",
)
