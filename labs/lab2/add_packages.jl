using Pkg
Pkg.activate(".")

# Основные пакеты для работы
packages = [
    "DrWatson",
    "Distributions",
    "Plots",
    "StatsPlots",
    "DataFrames",
    "JLD2",
    "Literate",
    "IJulia",
    "Random",
    "Statistics",
    "CSV"
]

println("Установка базовых пакетов...")
Pkg.add(packages)

println("\nВсе пакеты установлены!")
println("Для проверки: using DrWatson, DifferentialEquations, Plots")