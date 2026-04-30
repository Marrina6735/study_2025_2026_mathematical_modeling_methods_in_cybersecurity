##!/usr/bin/env julia
## add_packages.jl

using Pkg
Pkg.activate(".")

packages = [
    "DrWatson",
    "Graphs",
    "Plots",
    "GraphRecipes",
    "JLD2",
    "Distributions",
    "Random",
    "LinearAlgebra",
    "CSV",
    "DataFrames",
    "StatsPlots",
    "Literate"
]

println("Установка пакетов...")
Pkg.add(packages)
println("Все пакеты установлены!")