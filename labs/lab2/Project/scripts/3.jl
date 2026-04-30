# # Дополнительное задание 3: Исследование вероятностей событий
# 
# Анализ вероятностей:
# - "ни одной атаки за смену (8 часов)"
# - "не менее 3 атак за 30 минут"

using DrWatson
@quickactivate "Project"

using Distributions
using Statistics
using Random
using Plots
using DataFrames

include(srcdir("simulation.jl"))

# Параметры
λ = 5.0  # атак/час
n_simulations = 10000
Random.seed!(42)

println("=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 3: ИССЛЕДОВАНИЕ ВЕРОЯТНОСТЕЙ ===\n")

# ======================
# Событие 1: Ни одной атаки за смену (8 часов)
# ======================
shift_hours = 8.0
println("СОБЫТИЕ 1: Ни одной атаки за смену ($shift_hours часов)")

# Теоретическая вероятность
theor_prob_no_attacks_shift = pdf(Poisson(λ * shift_hours), 0)
println("  Теоретическая вероятность: $(round(theor_prob_no_attacks_shift, digits=6))")

# Эмпирическая оценка
no_attacks_count = 0
for i in 1:n_simulations
    res = simulate_attacks(λ, shift_hours)
    if sum(res.hourly_counts) == 0
        no_attacks_count += 1
    end
end
emp_prob_no_attacks_shift = no_attacks_count / n_simulations
println("  Эмпирическая вероятность ($n_simulations смен): $(round(emp_prob_no_attacks_shift, digits=6))")
println("  Относительная ошибка: $(round(abs(emp_prob_no_attacks_shift - theor_prob_no_attacks_shift)/theor_prob_no_attacks_shift*100, digits=2))%")

# ======================
# Событие 2: Не менее 3 атак за 30 минут
# ======================
half_hour = 0.5  # 30 минут = 0.5 часа
λ_half = λ * half_hour  # параметр для 30 минут
println("\nСОБЫТИЕ 2: Не менее 3 атак за 30 минут")

# Теоретическая вероятность
theor_prob_ge3_half = 1 - cdf(Poisson(λ_half), 2)
println("  Теоретическая вероятность: $(round(theor_prob_ge3_half, digits=6))")

# Эмпирическая оценка
ge3_count = 0
for i in 1:n_simulations
    res = simulate_attacks(λ, half_hour)
    if sum(res.hourly_counts) >= 3
        ge3_count += 1
    end
end
emp_prob_ge3_half = ge3_count / n_simulations
println("  Эмпирическая вероятность ($n_simulations интервалов): $(round(emp_prob_ge3_half, digits=6))")
println("  Относительная ошибка: $(round(abs(emp_prob_ge3_half - theor_prob_ge3_half)/theor_prob_ge3_half*100, digits=2))%")

# ======================
# Дополнительно: Зависимость от λ
# ======================
println("\n" * "=" ^ 60)
println("ЗАВИСИМОСТЬ ВЕРОЯТНОСТЕЙ ОТ ИНТЕНСИВНОСТИ λ")
println("=" ^ 60)

λ_range = 1:0.5:10
results_shift = []
results_half = []

for λ_val in λ_range
    # Для смены (8 часов)
    prob_shift = pdf(Poisson(λ_val * 8), 0)
    # Для 30 минут
    prob_half = 1 - cdf(Poisson(λ_val * 0.5), 2)
    push!(results_shift, prob_shift)
    push!(results_half, prob_half)
end

# График зависимости
p1 = plot(λ_range, results_shift,
    label = "P(ни одной атаки за 8 ч)",
    xlabel = "Интенсивность λ (атак/час)",
    ylabel = "Вероятность",
    title = "Вероятность отсутствия атак за смену",
    lw=2,
    color = :blue,
    marker = :circle)

p2 = plot(λ_range, results_half,
    label = "P(≥3 атак за 30 мин)",
    xlabel = "Интенсивность λ (атак/час)",
    ylabel = "Вероятность",
    title = "Вероятность интенсивных атак за полчаса",
    lw=2,
    color = :red,
    marker = :square)

combined = plot(p1, p2, layout = (2,1), size = (800, 600))
savefig(combined, plotsdir("event_probabilities.png"))
println("\nГрафик сохранён в ", plotsdir("event_probabilities.png"))

# ======================
# Анализ с использованием больших выборок
# ======================
println("\n" * "=" ^ 60)
println("АНАЛИЗ С БОЛЬШИМИ ВЫБОРКАМИ")
println("=" ^ 60)

sample_sizes = [100, 500, 1000, 5000, 10000, 50000, 100000]
errors_shift = []
errors_half = []

for n in sample_sizes
    # Оценка для смены
    no_attacks = 0
    for i in 1:n
        res = simulate_attacks(λ, shift_hours)
        if sum(res.hourly_counts) == 0
            no_attacks += 1
        end
    end
    emp_shift = no_attacks / n
    push!(errors_shift, abs(emp_shift - theor_prob_no_attacks_shift))
    
    # Оценка для 30 минут
    ge3 = 0
    for i in 1:n
        res = simulate_attacks(λ, half_hour)
        if sum(res.hourly_counts) >= 3
            ge3 += 1
        end
    end
    emp_half = ge3 / n
    push!(errors_half, abs(emp_half - theor_prob_ge3_half))
end

# График сходимости ошибок
p3 = plot(sample_sizes, errors_shift,
    xscale = :log10,
    yscale = :log10,
    label = "Смена (8 ч)",
    xlabel = "Размер выборки",
    ylabel = "Абсолютная ошибка",
    title = "Сходимость оценки вероятности",
    marker = :circle,
    lw=2,
    color = :blue)

plot!(p3, sample_sizes, errors_half,
    label = "30 минут (≥3 атак)",
    marker = :square,
    lw=2,
    color = :red)

savefig(p3, plotsdir("probability_convergence.png"))
println("График сходимости сохранён в ", plotsdir("probability_convergence.png"))

# Сохранение результатов
df_results = DataFrame(
    λ = λ_range,
    prob_no_attacks_8h = results_shift,
    prob_ge3_30min = results_half
)
CSV.write(datadir("event_probabilities_theoretical.csv"), df_results)
println("\nТеоретические значения сохранены в datadir(\"event_probabilities_theoretical.csv\")")