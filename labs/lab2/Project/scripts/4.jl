# # Дополнительное задание 4: Бутстреп для вероятности редкого события
# 
# Оценка доверительного интервала для вероятности P(N > 10) методом бутстрепа

using DrWatson
@quickactivate "Project"

using Distributions
using Statistics
using Random
using Plots

include(srcdir("simulation.jl"))

# Параметры
λ = 5.0
T = 24.0
n_bootstrap = 10000  # количество бутстреп-выборок
sample_size = 1000   # размер исходной выборки
Random.seed!(42)

println("=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 4: БУТСТРЕП ДЛЯ ВЕРОЯТНОСТИ ===\n")

# Функция для вычисления вероятности P(N > 10)
function compute_probability(sample)
    return count(sample .> 10) / length(sample)
end

# Генерация исходной выборки
original_sample = rand(Poisson(λ), sample_size)
original_prob = compute_probability(original_sample)
theoretical_prob = 1 - cdf(Poisson(λ), 10)

println("ИСХОДНЫЕ ДАННЫЕ:")
println("  Размер выборки: $sample_size")
println("  λ = $λ")
println("  Теоретическая P(N>10): $(round(theoretical_prob, digits=6))")
println("  Эмпирическая P(N>10): $(round(original_prob, digits=6))")

# Бутстреп
println("\nЗАПУСК БУТСТРЕПА ($n_bootstrap итераций)...")

bootstrap_estimates = Float64[]
for i in 1:n_bootstrap
    # Создание бутстреп-выборки с возвращением
    bootstrap_sample = rand(original_sample, sample_size)
    prob_est = compute_probability(bootstrap_sample)
    push!(bootstrap_estimates, prob_est)
    
    # Прогресс
    if i % 1000 == 0
        print("\r  Прогресс: $i/$n_bootstrap")
    end
end
println("\n")

# Статистика бутстреп-оценок
mean_bootstrap = mean(bootstrap_estimates)
std_bootstrap = std(bootstrap_estimates)

# Доверительные интервалы
alpha = 0.05  # 95% доверительный интервал
ci_lower_normal = mean_bootstrap - 1.96 * std_bootstrap
ci_upper_normal = mean_bootstrap + 1.96 * std_bootstrap

ci_lower_percentile = quantile(bootstrap_estimates, alpha/2)
ci_upper_percentile = quantile(bootstrap_estimates, 1 - alpha/2)

println("РЕЗУЛЬТАТЫ БУТСТРЕПА:")
println("  Среднее бутстреп-оценок: $(round(mean_bootstrap, digits=6))")
println("  Стандартное отклонение: $(round(std_bootstrap, digits=6))")
println("\n  95% ДОВЕРИТЕЛЬНЫЙ ИНТЕРВАЛ (нормальный):")
println("    [$(round(ci_lower_normal, digits=6)), $(round(ci_upper_normal, digits=6))]")
println("\n  95% ДОВЕРИТЕЛЬНЫЙ ИНТЕРВАЛ (процентильный):")
println("    [$(round(ci_lower_percentile, digits=6)), $(round(ci_upper_percentile, digits=6))]")
println("\n  Теоретическое значение внутри процентильного интервала: ", 
    ci_lower_percentile <= theoretical_prob <= ci_upper_percentile)

# Зависимость ширины интервала от размера выборки
println("\n" * "=" ^ 60)
println("ЗАВИСИМОСТЬ ШИРИНЫ ДИ И РАЗМЕРА ВЫБОРКИ")
println("=" ^ 60)

sample_sizes = [50, 100, 500, 1000, 5000, 10000]
bootstrap_n = 1000
ci_widths = []

for n in sample_sizes
    sample = rand(Poisson(λ), n)
    boot_estimates = Float64[]
    
    for i in 1:bootstrap_n
        boot_sample = rand(sample, n)
        push!(boot_estimates, compute_probability(boot_sample))
    end
    
    ci_width = quantile(boot_estimates, 0.975) - quantile(boot_estimates, 0.025)
    push!(ci_widths, ci_width)
    
    println("  n = $n: ширина CI = $(round(ci_width, digits=6))")
end

# Визуализация
p1 = histogram(bootstrap_estimates,
    bins = 50,
    normalize = :probability,
    label = "Бутстреп-оценки",
    xlabel = "Вероятность P(N>10)",
    ylabel = "Плотность",
    title = "Распределение бутстреп-оценок (n=$sample_size)",
    color = :lightblue,
    alpha = 0.7)

vline!(p1, [theoretical_prob],
    label = "Теоретическое значение",
    lw=3,
    color = :green)
vline!(p1, [ci_lower_percentile, ci_upper_percentile],
    label = "95% CI (процентильный)",
    lw=2,
    ls = :dash,
    color = :red)
vline!(p1, [original_prob],
    label = "Исходная оценка",
    lw=2,
    ls = :dot,
    color = :blue)

# Зависимость ширины CI от размера выборки
p2 = plot(sample_sizes, ci_widths,
    xscale = :log10,
    yscale = :log10,
    marker = :circle,
    markersize = 8,
    label = "Ширина CI",
    xlabel = "Размер выборки (log scale)",
    ylabel = "Ширина доверительного интервала (log scale)",
    title = "Зависимость ширины CI от размера выборки",
    lw=2,
    color = :red)

# Теоретическая кривая ~ 1/√n
fit_coeff = ci_widths[end] * sqrt(sample_sizes[end])
theoretical_widths = [fit_coeff / sqrt(n) for n in sample_sizes]
plot!(p2, sample_sizes, theoretical_widths,
    label = "Теоретическая ~ 1/√n",
    ls = :dash,
    lw=2,
    color = :blue)

combined = plot(p1, p2, layout = (2,1), size = (800, 800))
savefig(combined, plotsdir("bootstrap_analysis.png"))
println("\nГрафик сохранён в ", plotsdir("bootstrap_analysis.png"))

# Сравнение с нормальным приближением
println("\n" * "=" ^ 60)
println("СРАВНЕНИЕ С НОРМАЛЬНЫМ ПРИБЛИЖЕНИЕМ")
println("=" ^ 60)

# Нормальное приближение (асимптотическое)
std_normal = sqrt(theoretical_prob * (1 - theoretical_prob) / sample_size)
ci_normal_asymptotic = [theoretical_prob - 1.96*std_normal, theoretical_prob + 1.96*std_normal]

println("Асимптотический 95% CI: [$(round(ci_normal_asymptotic[1], digits=6)), $(round(ci_normal_asymptotic[2], digits=6))]")
println("Бутстреп 95% CI (процентильный): [$(round(ci_lower_percentile, digits=6)), $(round(ci_upper_percentile, digits=6))]")