using AnalyseDataSet
using Documenter

DocMeta.setdocmeta!(AnalyseDataSet, :DocTestSetup, :(using AnalyseDataSet); recursive=true)

makedocs(;
    modules=[AnalyseDataSet],
    authors="Robert Feldt",
    repo="https://github.com/robertfeldt/AnalyseDataSet.jl/blob/{commit}{path}#{line}",
    sitename="AnalyseDataSet.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://robertfeldt.github.io/AnalyseDataSet.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/robertfeldt/AnalyseDataSet.jl",
    devbranch="main",
)
