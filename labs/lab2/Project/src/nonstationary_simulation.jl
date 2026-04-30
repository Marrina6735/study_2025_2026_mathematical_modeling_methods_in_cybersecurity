# # Нестационарный пуассоновский поток атак
# 
# Моделирование потока с интенсивностью, зависящей от времени суток:
# λ(t) = 2 + 5 * sin(π * t / 12)

using DrWatson
@quickactivate "Project"

using Distributions
using Plots
using Random

# Функция интенсивности
λ_t(t) = 2.0 + 5.0 * sin(π * t / 12.0)

# Метод прореживания для нестационарного пуассоновского процесса
function simulate_nonstationary(T::Float64, λ_max::Float64)
    # Генерация однородного пуассоновского потока с λ_max
    λ_max = 7.0  # максимум λ(t) ≈ 7
    
    events = Float64[]
    t = 0.0
    
    while t < T
        τ = rand(Exponential(1/λ_max))
        t += τ
        
        if t <= T
            # Вероятность принятия события
            p_accept = λ_t(t) / λ_max
            if rand() < p_accept
                push!(events, t)
            end
        end
    end
    
    return events
end

# Параметры
T = 24.0
Random.seed!(42)

# Симуляция
events = simulate_nonstationary(T, 7.0)

# Вычисление числа атак по часам
hourly_counts = zeros(Int, floor(Int, T))
for event in events
    hour = floor(Int, event) + 1
    if hour <= length(hourly_counts)
        hourly_counts[hour] += 1
    end
end

# Визуализация
p1 = plot(0:0.1:T, λ_t.(0:0.1:T),
    label = "λ(t) = 2 + 5·sin(πt/12)",
    xlabel = "Время (ч)",
    ylabel = "Интенсивность λ(t)",
    title = "Нестационарная интенсивность атак",
    lw=2,
    color = :red)

p2 = bar(1:length(hourly_counts), hourly_counts,
    label = "Число атак",
    xlabel = "Час",
    ylabel = "Количество атак",
    title = "Почасовое распределение атак",
    color = :blue,
    alpha = 0.7)

combined = plot(p1, p2, layout = (2,1), size = (800, 600))
savefig(combined, plotsdir("nonstationary_simulation.png"))

println("Нестационарная симуляция завершена")
println("Всего атак за $(T) часов: ", length(events))
println("Среднее число атак в час: ", mean(hourly_counts))