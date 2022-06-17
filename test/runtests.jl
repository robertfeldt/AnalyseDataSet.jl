using AnalyseDataSet
using DataFrames
using Test

@testset "AnalyseDataSet.jl" begin
    df = DataFrame(
        Bin1 = Bool[true, false, true],
        Bin2 = Int[0, 1, 1],
        Bin3 = String["arne", "beda", "arne"],
        Cat1 = String["arne", "beda", "cathy"],
        Cat2 = Symbol[:a, :b, :c],
        OrdInt1 = Int[1, 2, 3],
        Cont1 = Float64[1.2, 3.4, 87.5]
    )
    res = AnalyseDataSet.analyse(df)
    @test occursin("N = 3", res)
    @test occursin("3 Binary", res)
    @test occursin("2 Categorical", res)
    @test occursin("1 Ordinal Integer", res)
    @test occursin("1 Continuous", res)
end
