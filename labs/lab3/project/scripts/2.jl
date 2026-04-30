using DrWatson
@quickactivate "project"
using Graphs, JLD2, Random, Plots
using Statistics  # <-- ДОБАВЛЯЕМ ЭТУ СТРОКУ для mean()

# Агентная модель распространения атаки

"""
Функция распространения атаки по графу
- g: граф
- source: начальный узел (откуда начинается атака)
- p_infect: вероятность заражения соседнего узла
- max_steps: максимальное количество шагов
"""
function spread_attack(g, source, p_infect=0.3, max_steps=10)
    n = nv(g)
    infected = falses(n)
    infected[source] = true
    newly_infected = [source]
    infection_history = [copy(infected)]
    step_times = [0]
    
    for step in 1:max_steps
        next_infected = []
        for node in newly_infected
            for neighbor in outneighbors(g, node)
                if !infected[neighbor] && rand() < p_infect
                    infected[neighbor] = true
                    push!(next_infected, neighbor)
                end
            end
        end
        newly_infected = next_infected
        push!(infection_history, copy(infected))
        push!(step_times, step)
        
        if isempty(newly_infected)
            break
        end
    end
    
    return infected, infection_history, step_times
end

"""
Многократный запуск для оценки вероятности заражения цели
"""
function estimate_infection_probability(g, source, target, p_infect, n_simulations=1000)
    success_count = 0
    infection_steps = []
    
    for sim in 1:n_simulations
        Random.seed!(sim)
        infected, history, steps = spread_attack(g, source, p_infect)
        
        if infected[target]
            success_count += 1
            for (idx, infected_state) in enumerate(history)
                if infected_state[target]
                    push!(infection_steps, steps[idx])
                    break
                end
            end
        end
    end
    
    probability = success_count / n_simulations
    avg_steps = isempty(infection_steps) ? 0.0 : mean(infection_steps)
    
    return probability, avg_steps, success_count
end

# Загрузка данных

# Параметры
params = Dict(:n => 20, :edge_prob => 0.2, :source => 1, :target => 20)

filename = datadir("attack_graph", savename(params, "jld2"))

if !isfile(filename)
    error("Файл $filename не найден. Сначала запустите scripts/ag_run_experiment.jl")
end

@load filename data

g = data[:graph]
source = 1
target = 20


println("АГЕНТНАЯ МОДЕЛЬ РАСПРОСТРАНЕНИЯ АТАКИ")

println("\nПараметры модели:")
println("  Количество узлов: ", nv(g))
println("  Количество рёбер: ", ne(g))
println("  Начальный узел (атакующий): ", source)
println("  Целевой узел (критический актив): ", target)

# Одиночный запуск для демонстрации

println("ДЕМОНСТРАЦИОННЫЙ ЗАПУСК (p_infect = 0.3)")

Random.seed!(42)
infected, infection_history, step_times = spread_attack(g, source, 0.3)

println("\nХод распространения атаки:")
for i in 1:length(step_times)
    step = step_times[i]
    infected_state = infection_history[i]
    infected_count = count(infected_state)
    infected_percent = infected_count / nv(g) * 100
    println("  Шаг ", step, ": заражено ", infected_count, " узлов (", round(infected_percent, digits=1), "%)")
    
    # Показываем, какие узлы заражены
    infected_nodes = findall(infected_state)
    if length(infected_nodes) <= 10
        println("           Заражённые узлы: ", infected_nodes)
    else
        print("           Заражённые узлы: ")
        println(infected_nodes[1:10], "... (всего ", length(infected_nodes), ")")
    end
end

# Проверка, достигла ли атака цели
if infected[target]
    println("\n АТАКА ДОСТИГЛА ЦЕЛИ! Узел ", target, " заражён.")
else
    println("\n АТАКА НЕ ДОСТИГЛА ЦЕЛИ. Узел ", target, " не заражён.")
end

# Исследование влияния вероятности заражения

println("ИССЛЕДОВАНИЕ ВЛИЯНИЯ ВЕРОЯТНОСТИ ЗАРАЖЕНИЯ")

p_values = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
results = []

println("\nЗапуск 1000 симуляций для каждого значения p_infect...\n")

for p in p_values
    prob, avg_steps, success_count = estimate_infection_probability(g, source, target, p, 1000)
    push!(results, (p=p, probability=prob, avg_steps=avg_steps, successes=success_count))
    print("p_infect = ", p, ": вероятность достижения цели = ", round(prob * 100, digits=1), "%")
    println(" (успехов: ", success_count, "/1000), средних шагов: ", round(avg_steps, digits=2))
end


# График 1: Зависимость вероятности от p_infect
p1 = plot(
    [r.p for r in results],
    [r.probability for r in results],
    marker=:circle,
    linewidth=2,
    xlabel="Вероятность заражения (p_infect)",
    ylabel="Вероятность достижения цели",
    title="Зависимость успеха атаки от вероятности заражения",
    label="Эмпирическая вероятность",
    legend=:bottomright,
)

# Добавляем теоретическую кривую для сравнения
theoretical = [r.p^3 for r in results]
plot!(p1, [r.p for r in results], theoretical, 
      linestyle=:dash, label="Теоретическая (p^3)", linewidth=2)

# График 2: Зависимость среднего числа шагов от p_infect
p2 = plot(
    [r.p for r in results],
    [r.avg_steps for r in results],
    marker=:square,
    linewidth=2,
    xlabel="Вероятность заражения (p_infect)",
    ylabel="Среднее число шагов до заражения",
    title="Скорость распространения атаки",
    label="Среднее количество шагов",
    legend=:topright,
)

# Объединяем графики
combined = plot(p1, p2, layout=(2, 1), size=(800, 600))
mkpath(plotsdir())
savefig(combined, plotsdir("agent_model_results.png"))
println("\nГрафики сохранены в ", plotsdir("agent_model_results.png"))

# Вывод статистики по графу

println("\n" * "-" ^ 40)
println("СТАТИСТИКА ГРАФА")
println("-" ^ 40)

println("\nСтепени узлов (количество связей):")
for i in 1:nv(g)
    outdeg = outdegree(g, i)
    indeg = indegree(g, i)
    total = outdeg + indeg
    println("  Узел ", i, ": исходящих = ", outdeg, ", входящих = ", indeg, ", всего = ", total)
end

println("\n" * "=" ^ 60)
println("ВЫВОДЫ ПО АГЕНТНОЙ МОДЕЛИ")
println("=" ^ 60)

# Находим лучший и худший результат
best_idx = argmax([r.probability for r in results])
worst_idx = argmin([r.probability for r in results])

println("""
Лучший результат достигнут при p_infect = $(p_values[best_idx]) (вероятность = $(round(results[best_idx].probability * 100, digits=1))%)
Худший результат при p_infect = $(p_values[worst_idx]) (вероятность = $(round(results[worst_idx].probability * 100, digits=1))%)
""")

