# # Дополнительное задание 6: Проверка гипотезы о пуассоновости
# 
# Использование реальных данных об атаках (симулированные или загруженные)

using DrWatson
@quickactivate "Project"

using Distributions
using Statistics
using Random
using Plots
using HypothesisTests
using CSV
using DataFrames

println("=== ДОПОЛНИТЕЛЬНОЕ ЗАДАНИЕ 6: ПРОВЕРКА ГИПОТЕЗЫ О ПУАССОНОВОСТИ ===\n")

# Поскольку реальные данные не предоставлены, создаём синтетические
# данные, имитирующие реальные наблюдения
Random.seed!(42)

println("ГЕНЕРАЦИЯ ТЕСТОВЫХ ДАННЫХ")
println("-" ^ 50)

# Вариант 1: Данные из пуассоновского распределения (H0 - верна)
λ_true = 5.0
n_days = 30  # 30 дней наблюдений
n_hours_per_day = 24
poisson_data = rand(Poisson(λ_true), n_days * n_hours_per_day)

# Вариант 2: Данные из негативного биномиального (overdispersion)
# (имитация реальных данных с большей дисперсией)
nb_r = 5
nb_p = 0.5
nb_mean = nb_r * (1 - nb_p) / nb_p
overdispersed_data = rand(NegativeBinomial(nb_r, nb_p), n_days * n_hours_per_day)

println("  Пуассоновские данные (H0 верна): λ = $λ_true")
println("  Негативно-биномиальные данные (overdispersion): μ = $(round(nb_mean, digits=1))")

# Функции для проверки гипотезы
function test_poisson_hypothesis(data, λ_est=nothing)
    n = length(data)
    
    # Оценка параметра λ
    if λ_est === nothing
        λ_est = mean(data)
    end
    
    # Критерий хи-квадрат
    # Группируем данные
    max_val = maximum(data)
    bins = 0:max_val
    observed_counts = [count(x .== i for x in data) for i in bins]
    
    # Ожидаемые частоты
    expected_counts = n * pdf.(Poisson(λ_est), bins)
    
    # Убираем bins с малыми ожидаемыми частотами
    valid_indices = expected_counts .>= 5
    observed_valid = observed_counts[valid_indices]
    expected_valid = expected_counts[valid_indices]
    
    if length(observed_valid) > 1
        # Хи-квадрат статистика
        chi2_stat = sum((observed_valid - expected_valid).^2 ./ expected_valid)
        df = length(observed_valid) - 2  # -1 за группировку, -1 за оценку параметра
        p_value = 1 - cdf(Chisq(df), chi2_stat)
        return (χ²=chi2_stat, df=df, p_value=p_value, λ_est=λ_est)
    else
        return (χ²=NaN, df=0, p_value=NaN, λ_est=λ_est)
    end
end

# Тестирование пуассоновских данных
println("\n" * "=" ^ 60)
println("ТЕСТ 1: ДАННЫЕ ИЗ ПУАССОНОВСКОГО РАСПРЕДЕЛЕНИЯ")
println("=" ^ 60)

result_poisson = test_poisson_hypothesis(poisson_data)
println("  Оценка λ: $(round(result_poisson.λ_est, digits=2))")
println("  χ² = $(round(result_poisson.χ², digits=2))")
println("  df = $(result_poisson.df)")
println("  p-value = $(round(result_poisson.p_value, digits=4))")

if result_poisson.p_value > 0.05
    println("  Результат: НЕ отвергаем H0 (данные соответствуют Пуассону)")
else
    println("  Результат: ОТВЕРГАЕМ H0 (данные НЕ соответствуют Пуассону)")
end

# Тестирование overdispersed данных
println("\n" * "=" ^ 60)
println("ТЕСТ 2: ДАННЫЕ С OVERDISPERSION (НЕГАТИВНОЕ БИНОМИАЛЬНОЕ)")
println("=" ^ 60)

result_nb = test_poisson_hypothesis(overdispersed_data)
println("  Оценка λ (среднее): $(round(result_nb.λ_est, digits=2))")
println("  Дисперсия данных: $(round(var(overdispersed_data), digits=2))")
println("  χ² = $(round(result_nb.χ², digits=2))")
println("  df = $(result_nb.df)")
println("  p-value = $(round(result_nb.p_value, digits=6))")

if result_nb.p_value > 0.05
    println("  Результат: НЕ отвергаем H0 (данные соответствуют Пуассону)")
else
    println("  Результат: ОТВЕРГАЕМ H0 (данные НЕ соответствуют Пуассону)")
end

# Визуализация
p1 = histogram(poisson_data,
    bins = 0:maximum(poisson_data),
    normalize = :probability,
    label = "Эмпирические данные",
    xlabel = "Число атак за час",
    ylabel = "Вероятность",
    title = "Пуассоновские данные (λ = $λ_true)",
    color = :lightblue,
    alpha = 0.7)

x_vals = 0:maximum(poisson_data)
theor_probs = pdf.(Poisson(λ_true), x_vals)
plot!(p1, x_vals, theor_probs,
    line = :stem,
    marker = :circle,
    label = "Теоретическое Пуассона(λ=$λ_true)",
    color = :red)

p2 = histogram(overdispersed_data,
    bins = 0:maximum(overdispersed_data),
    normalize = :probability,
    label = "Эмпирические данные",
    xlabel = "Число атак за час",
    ylabel = "Вероятность",
    title = "Данные с overdispersion",
    color = :lightcoral,
    alpha = 0.7)

# Теоретическое пуассоновское с тем же средним
λ_est = mean(overdispersed_data)
theor_probs_nb = pdf.(Poisson(λ_est), x_vals)
plot!(p2, x_vals, theor_probs_nb,
    line = :stem,
    marker = :circle,
    label = "Пуассона(λ=$(round(λ_est, digits=1)))",
    color = :blue)

# QQ-plot для проверки
p3 = qqplot(Poisson(λ_true), poisson_data,
    qqline = :identity,
    xlabel = "Теоретические квантили (Пуассон)",
    ylabel = "Эмпирические квантили",
    title = "QQ-plot: Пуассоновские данные",
    color = :blue,
    alpha = 0.7)

p4 = qqplot(Poisson(mean(overdispersed_data)), overdispersed_data,
    qqline = :identity,
    xlabel = "Теоретические квантили (Пуассон)",
    ylabel = "Эмпирические квантили",
    title = "QQ-plot: Overdispersed данные",
    color = :red,
    alpha = 0.7)

# Сравнение дисперсий
p5 = bar(["Пуассон", "Overdispersed"],
    [var(poisson_data), var(overdispersed_data)],
    label = "Эмпирическая дисперсия",
    ylabel = "Дисперсия",
    title = "Сравнение дисперсий",
    color = [:lightblue, :lightcoral])

hline!([λ_true], label = "Теоретическая дисперсия (λ)", ls = :dash, color = :green)

combined = plot(p1, p2, p3, p4, p5, layout = (3,2), size = (1200, 1000))
savefig(combined, plotsdir("poisson_hypothesis_test.png"))
println("\nГрафик сохранён в ", plotsdir("poisson_hypothesis_test.png"))

# Критерий отношения дисперсии к среднему (дисперсионный индекс)
println("\n" * "=" ^ 60)
println("ДИСПЕРСИОННЫЙ ИНДЕКС (VARIANCE-TO-MEAN RATIO)")
println("=" ^ 60)

v_mean_poisson = var(poisson_data) / mean(poisson_data)
v_mean_nb = var(overdispersed_data) / mean(overdispersed_data)

println("  Пуассоновские данные: дисперсия/среднее = $(round(v_mean_poisson, digits=3))")
println("  Overdispersed данные: дисперсия/среднее = $(round(v_mean_nb, digits=3))")
println("\n  Для пуассоновского распределения дисперсия/среднее = 1")
println("  Overdispersion: дисперсия > среднего")

# Сохранение данных для дальнейшего анализа
df_poisson = DataFrame(hourly_attacks=poisson_data)
df_nb = DataFrame(hourly_attacks=overdispersed_data)

CSV.write(datadir("poisson_test_data.csv"), df_poisson)
CSV.write(datadir("overdispersed_test_data.csv"), df_nb)

println("\nТестовые данные сохранены в datadir/")
println("  - poisson_test_data.csv")
println("  - overdispersed_test_data.csv")