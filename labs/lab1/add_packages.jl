using Pkg
Pkg.activate(".")

# Основные пакеты для работы
packages = [
    "DrWatson",              # Организация проекта
    "DifferentialEquations", # Решение ОДУ
    "Plots",                  # Визуализация
    "DataFrames",            # Таблицы данных
    "CSV",                    # Работа с CSV
    "JLD2",                   # Сохранение данных
    "Literate",               # Literate programming
    "IJulia",                 # Jupyter notebook
    "BenchmarkTools"          # Бенчмаркинг
]

println("Установка базовых пакетов...")
Pkg.add(packages)

println("\nВсе пакеты установлены!")
println("Для проверки: using DrWatson, DifferentialEquations, Plots")