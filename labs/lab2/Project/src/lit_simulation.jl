# # Моделирование пуассоновского потока атак
# 
# **Цель работы:** Освоить базовые методы вероятностного моделирования 
# случайных процессов в контексте кибербезопасности.
# 
# ## Инициализация проекта и загрузка пакетов

using DrWatson
@quickactivate "Project"

using Distributions
using Plots
using StatsPlots
using JLD2
using Random
using Statistics
using DataFrames

# ## Параметры модели

params = Dict(
    :λ => 5.0,      # интенсивность атак (в час)
    :T => 24.0,     # период моделирования (часов)
)

# ## Функция симуляции
# 
# Моделируем пуассоновский поток атак. Интервалы между атаками имеют
# экспоненциальное распределение с параметром λ.

function simulate_attacks(λ::Float64, T::Float64)
    # Моделирование числа атак по часам
    hourly_counts = rand(Poisson(λ), floor(Int, T))
    
    # Моделирование точных моментов атак
    intervals = Float64[]
    total_time = 0.0
    
    while total_time < T
        τ = rand(Exponential(1/λ))
        push!(intervals, τ)
        total_time += τ
    end
    
    if total_time > T
        pop!(intervals)
    end
    
    attack_times = cumsum(intervals)
    
    return (hourly_counts=hourly_counts, intervals=intervals, 
            attack_times=attack_times)
end

# ## Запуск симуляции

Random.seed!(42)
res = simulate_attacks(params[:λ], params[:T])

# ## Визуализация результатов

# ### 1. Распределение числа атак за час

p1 = histogram(res.hourly_counts,
    bins = 0:maximum(res.hourly_counts),
    normalize = :probability,
    label = "Эмпирическая частота",
    xlabel = "Число атак за час",
    ylabel = "Вероятность",
    color = :lightblue,
    alpha = 0.7)

x_vals = 0:maximum(res.hourly_counts)
theor_probs = pdf.(Poisson(params[:λ]), x_vals)
plot!(p1, x_vals, theor_probs,
    line = :stem,
    marker = :circle,
    label = "Пуассона(λ=$(params[:λ]))",
    color = :red)
title!(p1, "Распределение числа атак за час")

# ### 2. Накопленное число атак

p2 = plot(res.attack_times, 1:length(res.attack_times),
    label = "Реализация",
    xlabel = "Время (ч)",
    ylabel = "Накопленное число атак",
    color = :blue,
    lw=2)

plot!(p2, 0:0.1:params[:T], params[:λ]*(0:0.1:params[:T]),
    label = "Среднее λ·t",
    ls = :dash,
    color = :red)
title!(p2, "Накопленное число атак")

# ### 3. Распределение интервалов между атаками

p3 = histogram(res.intervals,
    bins = 30,
    normalize = :pdf,
    label = "Эмпирическая плотность",
    xlabel = "Интервал (ч)",
    ylabel = "Плотность",
    color = :lightgreen,
    alpha = 0.7)

x_dens = range(0, maximum(res.intervals), length=100)
theor_dens = pdf.(Exponential(1/params[:λ]), x_dens)
plot!(p3, x_dens, theor_dens,
    label = "Экспоненциальная",
    lw=2,
    color = :red)
title!(p3, "Распределение интервалов между атаками")

# ### 4. QQ-plot интервалов

p4 = qqplot(Exponential(1/params[:λ]), res.intervals,
    qqline = :identity,
    xlabel = "Теоретические квантили",
    ylabel = "Эмпирические квантили",
    title = "QQ-plot интервалов",
    color = :blue,
    alpha = 0.7)

# ## Объединение и сохранение графиков

combined = plot(p1, p2, p3, p4, layout = (2,2), size = (1000, 800))
savefig(combined, plotsdir("literate_simulation.png"))

println("Графики сохранены в ", plotsdir("literate_simulation.png"))
display(combined)

# ## Статистический анализ

# Вычисление основных статистик
println("\n=== СТАТИСТИЧЕСКИЙ АНАЛИЗ ===")
println("Среднее число атак за час: ", mean(res.hourly_counts))
println("Дисперсия числа атак за час: ", var(res.hourly_counts))
println("Теоретическое среднее (λ): ", params[:λ])
println("Количество атак за период: ", sum(res.hourly_counts))
println("Количество интервалов: ", length(res.intervals))

# Оценка вероятности редкого события
num_hours_for_est = 100000
hourly_sample = rand(Poisson(params[:λ]), num_hours_for_est)
emp_prob = count(hourly_sample .> 10) / num_hours_for_est
theor_prob = 1 - cdf(Poisson(params[:λ]), 10)

println("\n=== ВЕРОЯТНОСТЬ P(N>10) ===")
println("Эмпирическая оценка: ", round(emp_prob, digits=6))
println("Теоретическое значение: ", round(theor_prob, digits=6))
println("Относительная ошибка: ", round(abs(emp_prob - theor_prob)/theor_prob*100, digits=2), "%")