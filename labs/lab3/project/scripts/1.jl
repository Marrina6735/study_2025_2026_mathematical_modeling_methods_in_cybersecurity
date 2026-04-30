using DrWatson
@quickactivate "project"
using Graphs, JLD2, LinearAlgebra

"""
Поиск наиболее вероятного пути с помощью алгоритма Дейкстры
"""
function find_most_likely_path(g, source, target, weights)
    n = nv(g)
    
    # Создаём матрицу весов для алгоритма Дейкстры
    # Используем -log(probability) для преобразования
    distmx = fill(Inf, n, n)
    for e in edges(g)
        u, v = src(e), dst(e)
        w = weights[e]
        distmx[u, v] = -log(w)  # Логарифмическое преобразование
    end
    
    # Запуск алгоритма Дейкстры
    state = dijkstra_shortest_paths(g, source, distmx)
    dist = state.dists
    parents = state.parents
    
    if dist[target] == Inf
        return [], 0.0
    end
    
    # Восстанавливаем путь
    path = Int[]
    current = target
    while current != source
        push!(path, current)
        current = parents[current]
    end
    push!(path, source)
    reverse!(path)
    
    # Преобразуем обратно в вероятность
    probability = exp(-dist[target])
    
    return path, probability
end


# Параметры 
params = Dict(:n => 20, :edge_prob => 0.2, :source => 1, :target => 20)

# Формируем имя файла
filename = datadir("attack_graph", savename(params, "jld2"))

# Проверяем существование файла
if !isfile(filename)
    error("Файл $filename не найден. Сначала запустите scripts/ag_run_experiment.jl")
end

# Загружаем данные
@load filename data

println("Наиболее вероятный путь (Дейкстра) ")
println("Путь: ", data[:likely_path])
println("Вероятность: ", round(data[:probability], digits=4))

# Дополнительно: найдём все пути и сравним их вероятности
println("\n=== Сравнение всех путей ===")

# Получаем веса рёбер из данных
weights = data[:weights]
paths = data[:paths]

best_path = data[:likely_path]
best_prob = data[:probability]

println("\nВсе пути и их вероятности:")
for (i, path) in enumerate(paths)
    # Вычисляем вероятность пути
    prob = 1.0
    for j in 1:(length(path)-1)
        u, v = path[j], path[j+1]
        for e in edges(data[:graph])
            if src(e) == u && dst(e) == v
                prob *= weights[e]
                break
            end
        end
    end
    
    marker = path == best_path ? "НАИБОЛЕЕ ВЕРОЯТНЫЙ" : ""
    println("Путь $i: $(join(path, " → "))")
    println("        Вероятность: $(round(prob, digits=6))$marker\n")
end

# Статистика
println("Статистика ")
println("Всего путей: $(length(paths))")
println("Наиболее вероятный путь: $(join(best_path, " → "))")
println("Его вероятность: $(round(best_prob * 100, digits=2))%")