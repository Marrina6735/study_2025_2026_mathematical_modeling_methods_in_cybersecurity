# # Дополнительное задание 1: Сравнение разных интенсивностей атак
# 
# Исследование влияния параметра λ на характеристики потока атак

using DrWatson
@quickactivate "Project"

using Distributions
using Plots
using Statistics
using Random
using DataFrames

include(srcdir("simulation.jl"))

# Параметры эксперимента
λ_values = [2.0, 8.0, 12.0]
T = 24.0
Random.seed!(42)

println("=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 1: СРАВНЕНИЕ РАЗНЫХ ИНТЕНСИВНОСТЕЙ ===\n")

# Хранение результатов
results = []

for λ in λ_values
    println("Интенсивность λ = $λ атак/час")
    println("-" ^ 40)
    
    # Симуляция
    res = simulate_attacks(λ, T)
    
    # Статистика
    mean_attacks = mean(res.hourly_counts)
    var_attacks = var(res.hourly_counts)
    total_attacks = sum(res.hourly_counts)
    
    # Вероятность P(N > 10)
    theor_prob_gt10 = 1 - cdf(Poisson(λ), 10)
    emp_prob_gt10 = count(res.hourly_counts .> 10) / length(res.hourly_counts)
    
    # Вероятность P(N = 0) за час
    theor_prob_zero = pdf(Poisson(λ), 0)
    emp_prob_zero = count(res.hourly_counts .== 0) / length(res.hourly_counts)
    
    push!(results, Dict(
        :λ => λ,
        :mean => mean_attacks,
        :var => var_attacks,
        :total => total_attacks,
        :theor_gt10 => theor_prob_gt10,
        :emp_gt10 => emp_prob_gt10,
        :theor_zero => theor_prob_zero,
        :emp_zero => emp_prob_zero
    ))
    
    println("  Среднее число атак/час: $(round(mean_attacks, digits=2)) (теор: $λ)")
    println("  Дисперсия: $(round(var_attacks, digits=2)) (теор: $λ)")
    println("  Всего атак за $T ч: $total_attacks (теор: $(λ*T))")
    println("  P(N>10): теор=$(round(theor_prob_gt10, digits=4)), эмп=$(round(emp_prob_gt10, digits=4))")
    println("  P(N=0): теор=$(round(theor_prob_zero, digits=4)), эмп=$(round(emp_prob_zero, digits=4))")
    println()
end

# Визуализация
figures = []

for λ in λ_values
    res = simulate_attacks(λ, T)
    
    # Гистограмма числа атак
    p1 = histogram(res.hourly_counts,
        bins = 0:maximum(res.hourly_counts),
        normalize = :probability,
        label = "Эмпирическая",
        xlabel = "Число атак за час",
        ylabel = "Вероятность",
        title = "λ = $λ",
        color = :lightblue,
        alpha = 0.7)
    
    x_vals = 0:maximum(res.hourly_counts)
    theor_probs = pdf.(Poisson(λ), x_vals)
    plot!(p1, x_vals, theor_probs,
        line = :stem,
        marker = :circle,
        label = "Пуассона(λ=$λ)",
        color = :red)
    
    push!(figures, p1)
end

# Объединение графиков
comparison = plot(figures..., layout = (1, 3), size = (1200, 400))
savefig(comparison, plotsdir("lambda_comparison.png"))
println("График сравнения сохранён в ", plotsdir("lambda_comparison.png"))

# Таблица результатов
df = DataFrame(results)
CSV.write(datadir("lambda_comparison_results.csv"), df)
println("\nТаблица результатов сохранена в datadir(\"lambda_comparison_results.csv\")")

# Вывод таблицы
println("\n=== СВОДНАЯ ТАБЛИЦА РЕЗУЛЬТАТОВ ===")
display(df)