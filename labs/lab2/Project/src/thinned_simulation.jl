# # Прореженный пуассоновский поток атак
# 
# Каждая атака имеет вероятность успеха p_success

using DrWatson
@quickactivate "Project"

using Distributions
using Plots
using Random
using Statistics

function simulate_thinned_attacks(λ::Float64, T::Float64, p_success::Float64)
    # Генерация всех атак
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
    n_attacks = length(attack_times)
    
    # Прореживание: успешные атаки
    success_flags = rand(n_attacks) .< p_success
    successful_times = attack_times[success_flags]
    failed_times = attack_times[.!success_flags]
    
    return (all_times=attack_times, successful_times=successful_times,
            failed_times=failed_times, p_success=p_success)
end

# Параметры
λ = 5.0
T = 24.0
p_success_values = [0.1, 0.3, 0.5, 0.7, 0.9]

Random.seed!(42)

println("=== ПРОРЕЖЕННЫЙ ПУАССОНОВСКИЙ ПОТОК ===\n")

for p_success in p_success_values
    res = simulate_thinned_attacks(λ, T, p_success)
    
    println("p_success = $p_success:")
    println("  Всего атак: $(length(res.all_times))")
    println("  Успешных: $(length(res.successful_times))")
    println("  Доля успешных: $(round(length(res.successful_times)/length(res.all_times), digits=3))")
    println()
    
    # Визуализация для p_success = 0.5
    if p_success == 0.5
        p = plot(title = "Прореженный поток атак (p_success = 0.5)",
            xlabel = "Время (ч)", ylabel = "События")
        
        scatter!(p, res.failed_times, fill(0.2, length(res.failed_times)),
            label = "Неуспешные атаки", color = :red, markersize = 5)
        scatter!(p, res.successful_times, fill(0.8, length(res.successful_times)),
            label = "Успешные атаки", color = :green, markersize = 6)
        
        savefig(p, plotsdir("thinned_attacks_p=$(p_success).png"))
    end
end