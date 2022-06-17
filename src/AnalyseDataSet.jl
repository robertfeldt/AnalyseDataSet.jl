module AnalyseDataSet

using DataFrames, CSV

export analyse

abstract type AbstractVariateAnalysis end

struct VarAnalysis <: AbstractVariateAnalysis
    sometimesmissing::Bool
    maintype::String
    uvals
end

numunique(va::VarAnalysis) = length(va.uvals)
missingpenalty(va::VarAnalysis) = va.sometimesmissing ? 0.5 : 0.0
penalty(va::VarAnalysis) = (1.0 - 0.5 / numunique(va) + missingpenalty(va))

function overallcomplexity(va::VarAnalysis) # 1-2
    if occursin(r"^Binary", va.maintype)
        1.0
    elseif occursin(r"^Categorical", va.maintype) # 2-4
        c = 2.0 + penalty(va)
        occursin(r"likert", va.maintype) && return (c + 1.0)
        return c
    elseif occursin(r"^Ordinal", va.maintype) # 5-6
        return 5.0 + penalty(va)
    elseif occursin(r"^Ordinal", va.maintype) # 5-6
        return 5.0 + penalty(va)
    elseif occursin(r"^Integer", va.maintype) # 6-7
        return 6.0 + penalty(va)
    elseif occursin(r"^Continuous", va.maintype) # 7-8
        return 7.0 + penalty(va)
    elseif occursin(r"^Mixed", va.maintype) # 8-9
        return 8.0 + penalty(va)
    end
end

function summarytype(va::VarAnalysis)
    m = match(r"^([A-Za-z\s]+)", va.maintype)
    isnothing(m) && return "Unknown"
    occursin("likert", va.maintype) ? (m[1] * " likert") : m[1]
end

function summarize_analyses(df::DataFrame, vas::AbstractVector{<:AbstractVariateAnalysis})
    persummarytype = Dict{String, Vector{AbstractVariateAnalysis}}()
    for va in sort(vas, by = overallcomplexity)
        st = summarytype(va)
        push!(get!(persummarytype, st, AbstractVariateAnalysis[]), va)
    end
    sorted = sort(collect(persummarytype), by = t -> overallcomplexity(first(last(t))))
    vars = join(map(t -> string(length(t[2])) * " " * summarytype(first(t[2])), sorted), ", ")
    return "N = $(nrow(df)), $(length(vas)) vars: " * vars
end

"""
    analyse(df::DataFrame)

    Analyse the columns of a data frame and return a terse summary.
"""
function analyse(df::DataFrame)
    colanalyses = AbstractVariateAnalysis[analysecolumn(df, c) for c in 1:ncol(df)]
    @info string(length(colanalyses))
    summarize_analyses(df, colanalyses)
end

analyse(filepath::String) = analyse(CSV.read(filepath, DataFrame))

function analysecolumn(df::DataFrame, c::Union{Int, String, Symbol})
    uvals = unique(df[:, c])
    sometimesmissing = any(ismissing, uvals)
    nonemissinguvals = sort(filter(v -> !ismissing(v), uvals))
    types = unique(map(typeof, nonemissinguvals))
    if all(t -> t <: Integer, types)
        desc = "Integer($(length(nonemissinguvals)))"
        if length(nonemissinguvals) < 10
            if length(nonemissinguvals) == 2
                return VarAnalysis(sometimesmissing, "Binary", nonemissinguvals)
            else
                return VarAnalysis(sometimesmissing, "Ordinal $desc", nonemissinguvals)
            end
        else
            return VarAnalysis(sometimesmissing, desc, nonemissinguvals)
        end
    elseif all(t -> t <: AbstractString, types)
        # Possibly likert scale?
        desc = if 3 <= length(nonemissinguvals) <= 7 && islikert(nonemissinguvals)
            "Categorical($(length(nonemissinguvals)), likert)"
        elseif length(nonemissinguvals) == 2
            "Binary"
        else
            "Categorical($(length(nonemissinguvals)))"
        end
        return VarAnalysis(sometimesmissing, desc, nonemissinguvals)
    elseif all(t -> t <: Real, types)
        return VarAnalysis(sometimesmissing, "Continuous", nonemissinguvals)
    else
        typedesc = join(map(string, sort(types)), ", ")
        return VarAnalysis(sometimesmissing, "Mixed($typedesc)", nonemissinguvals)
    end
end

hassameelements(v1::AbstractVector{T}, v2::AbstractVector{T}) where T =
    hassameelements(collect(v1), collect(v2))

function hassameelements(v1::Vector{T}, v2::Vector{T}) where T
    length(v1) == length(v2) && all(e2 -> in(e2, v1), v2)
end

function islikert(nonmissingtype::AbstractVector{<:AbstractString})
    uvals = map(lowercase, collect(nonmissingtype))
    hassameelements(uvals, ["very infrequently", "very frequently", "almost never", "almost always", "somewhat frequently", "somewhat infrequently"]) ||
      hassameelements(uvals, ["sometimes", "often", "very often or always", "very rarely or never", "rarely"]) ||
      hassameelements(uvals, ["agree", "slightly agree", "mixed or neither agree nor disagree", "strongly agree", "strongly disagree", "disagree", "slightly disagree"]) ||
      hassameelements(uvals, ["rather true", "exactly true", "hardly true", "not true"]) ||
      hassameelements(uvals, ["some of the time", "a little of the time", "none of the time", "most of the time", "all of the time"])
end

end
