using DrWatson
@quickactivate "project"
using Graphs, JLD2, Plots, Statistics, Random

# ============================================
# Функции для работы с графом
# ============================================

"""
Поиск всех путей от source до target (DFS)
"""
function find_all_paths(g, source, target)
    paths = []
    
    function dfs(current, path)
        if current == target
            push!(paths, copy(path))
            return
        end
        for neighbor in outneighbors(g, current)
            if !(neighbor in path)
                push!(path, neighbor)
                dfs(neighbor, path)
                pop!(path)
            end
        end
    end
    
    dfs(source, [source])
    return paths
end

"""
Поиск наиболее вероятного пути с помощью алгоритма Дейкстры
"""
function most_likely_path(g, source, target, weights)
    n = nv(g)
    
    # Создаём матрицу весов
    distmx = fill(Inf, n, n)
    for e in edges(g)
        u, v = src(e), dst(e)
        w = get(weights, (u, v), 0.5)
        distmx[u, v] = -log(w)
    end
    
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
    
    prob = exp(-dist[target])
    return path, prob
end

"""
Вычисление PageRank
"""
function compute_pagerank(g; α=0.85, max_iter=100, tol=1e-6)
    n = nv(g)
    n == 0 && return Float64[]
    
    pr = fill(1.0 / n, n)
    
    for _ in 1:max_iter
        pr_new = fill((1-α)/n, n)
        
        for i in 1:n
            outdeg = outdegree(g, i)
            if outdeg > 0
                for j in outneighbors(g, i)
                    pr_new[j] += α * pr[i] / outdeg
                end
            else
                for j in 1:n
                    pr_new[j] += α * pr[i] / n
                end
            end
        end
        
        diff = maximum(abs.(pr_new - pr))
        pr = pr_new
        if diff < tol
            break
        end
    end
    
    return pr
end

"""
Удаление узла из графа (изоляция)
"""
function remove_node(g, node)
    g2 = copy(g)
    # Удаляем все рёбра, связанные с узлом
    for v in vertices(g2)
        if v == node
            continue
        end
        if has_edge(g2, v, node)
            rem_edge!(g2, v, node)
        end
        if has_edge(g2, node, v)
            rem_edge!(g2, node, v)
        end
    end
    return g2
end

# ============================================
# Загрузка данных
# ============================================

# Параметры
params = Dict(:n => 20, :edge_prob => 0.2, :source => 1, :target => 20)

filename = datadir("attack_graph", savename(params, "jld2"))

if !isfile(filename)
    error("Файл $filename не найден. Сначала запустите scripts/ag_run_experiment.jl")
end

@load filename data

g = data[:graph]
metrics = data[:metrics]
paths = data[:paths]
weights = data[:weights]
likely_path = data[:likely_path]
probability = data[:probability]

source = 1
target = 20

println("=" ^ 70)
println("ОЦЕНКА ЭФФЕКТИВНОСТИ ЗАЩИТНЫХ МЕР")
println("=" ^ 70)

# ============================================
# Исходное состояние
# ============================================

println("\n" * "-" ^ 70)
println("ИСХОДНОЕ СОСТОЯНИЕ СЕТИ")
println("-" ^ 70)

println("Количество узлов: ", nv(g))
println("Количество рёбер: ", ne(g))
println("Количество путей атаки от 1 к 20: ", length(paths))
println("Наиболее вероятный путь: ", join(likely_path, " → "))
println("Вероятность успеха: ", round(probability * 100, digits=2), "%")

# ============================================
# Выявление критических узлов
# ============================================

println("\n" * "-" ^ 70)
println("ВЫЯВЛЕНИЕ КРИТИЧЕСКИХ УЗЛОВ")
println("-" ^ 70)

# Метрики для оценки критичности
in_deg = metrics[:in_degree]
pagerank = metrics[:pagerank]
betweenness = metrics[:betweenness]

# Нормализуем метрики для комбинированной оценки
min_indeg, max_indeg = minimum(in_deg), maximum(in_deg)
min_pr, max_pr = minimum(pagerank), maximum(pagerank)
min_betw, max_betw = minimum(betweenness), maximum(betweenness)

if max_indeg > min_indeg
    norm_indeg = (in_deg .- min_indeg) ./ (max_indeg - min_indeg)
else
    norm_indeg = fill(0.5, nv(g))
end

if max_pr > min_pr
    norm_pr = (pagerank .- min_pr) ./ (max_pr - min_pr)
else
    norm_pr = fill(0.5, nv(g))
end

if max_betw > min_betw
    norm_betw = (betweenness .- min_betw) ./ (max_betw - min_betw)
else
    norm_betw = fill(0.5, nv(g))
end

# Комбинированная оценка критичности (среднее арифметическое)
criticality_score = (norm_indeg + norm_pr + norm_betw) / 3

# Топ-5 критических узлов
top_critical = sortperm(criticality_score, rev=true)[1:min(5, nv(g))]

println("\nКритические узлы (по комбинированной оценке):")
for (rank, node) in enumerate(top_critical)
    println("  ", rank, ". Узел ", node, 
            " (оценка = ", round(criticality_score[node], digits=3),
            ", in-degree=", in_deg[node],
            ", PageRank=", round(pagerank[node], digits=4),
            ", betweenness=", round(betweenness[node], digits=2), ")")
end

# ============================================
# Анализ защитных мер
# ============================================

println("\n" * "-" ^ 70)
println("АНАЛИЗ ЗАЩИТНЫХ МЕР")
println("-" ^ 70)

# Список узлов для изоляции (топ-5 критических)
nodes_to_test = top_critical[1:min(5, length(top_critical))]

results_comparison = []

println("\nИзоляция критических узлов:")
println()
println("+--------------+------------------+-------------------+-----------------+")
println("| Изолированный |    Количество    |    Вероятность    |    Снижение     |")
println("|    узел       |      путей       |    успеха (%)     |  вероятности (%) |")
println("+--------------+------------------+-------------------+-----------------+")

for node in nodes_to_test
    # Создаём граф без узла
    g_isolated = remove_node(g, node)
    
    # Находим пути в изолированном графе
    paths_isolated = find_all_paths(g_isolated, source, target)
    
    # Инициализируем переменные
    prob_isolated = 0.0
    prob_percent = 0.0
    
    if !isempty(paths_isolated)
        # Находим наиболее вероятный путь
        likely_path_isolated, prob_isolated = most_likely_path(g_isolated, source, target, weights)
        prob_percent = prob_isolated * 100
    end
    
    # Вычисляем снижение
    if probability > 0
        reduction = ((probability - prob_isolated) / probability) * 100
    else
        reduction = 0.0
    end
    
    push!(results_comparison, (node=node, paths=length(paths_isolated), 
                                prob=prob_percent, reduction=reduction))
    
    # Вывод строки таблицы
    node_str = rpad(string(node), 12)
    paths_str = rpad(string(length(paths_isolated)), 16)
    prob_str = rpad(string(round(prob_percent, digits=2)), 17)
    red_str = rpad(string(round(reduction, digits=1)), 15)
    println("| ", node_str, " | ", paths_str, " | ", prob_str, " | ", red_str, " |")
end
println("+--------------+------------------+-------------------+-----------------+")

# ============================================
# Детальный анализ изоляции самого критического узла
# ============================================

println("\n" * "-" ^ 70)
println("ДЕТАЛЬНЫЙ АНАЛИЗ ИЗОЛЯЦИИ САМОГО КРИТИЧЕСКОГО УЗЛА")
println("-" ^ 70)

most_critical = top_critical[1]
g_isolated = remove_node(g, most_critical)
paths_isolated = find_all_paths(g_isolated, source, target)
likely_path_isolated, prob_isolated = most_likely_path(g_isolated, source, target, weights)

println("\nИзолированный узел: ", most_critical)
println("\nДО ИЗОЛЯЦИИ:")
println("  - Количество путей: ", length(paths))
println("  - Наиболее вероятный путь: ", join(likely_path, " → "))
println("  - Вероятность успеха: ", round(probability * 100, digits=2), "%")

println("\nПОСЛЕ ИЗОЛЯЦИИ:")
println("  - Количество путей: ", length(paths_isolated))
if !isempty(likely_path_isolated)
    println("  - Наиболее вероятный путь: ", join(likely_path_isolated, " → "))
    println("  - Вероятность успеха: ", round(prob_isolated * 100, digits=2), "%")
else
    println("  - Путей атаки не найдено!")
    println("  - Вероятность успеха: 0.0%")
end

if probability > 0
    reduction_total = ((probability - prob_isolated) / probability) * 100
    println("\nОбщее снижение вероятности: ", round(reduction_total, digits=1), "%")
else
    println("\nОбщее снижение вероятности: 0.0%")
    reduction_total = 0.0
end

# ============================================
# Визуализация результатов
# ============================================

println("\n" * "-" ^ 70)
println("ВИЗУАЛИЗАЦИЯ")
println("-" ^ 70)

mkpath(plotsdir())

# График 1: Сравнение количества путей до и после изоляции
labels = [string(r.node) for r in results_comparison]
before_paths = [length(paths) for _ in results_comparison]
after_paths = [r.paths for r in results_comparison]

p1 = bar(
    labels,
    [before_paths after_paths],
    bar_width=0.6,
    title="Сравнение количества путей атаки",
    xlabel="Изолированный узел",
    ylabel="Количество путей",
    label=["До изоляции" "После изоляции"]
)

savefig(p1, plotsdir("defense_paths_comparison.png"))
println("График сравнения путей сохранён в ", plotsdir("defense_paths_comparison.png"))

# График 2: Сравнение вероятностей до и после изоляции
before_probs = [probability * 100 for _ in results_comparison]
after_probs = [r.prob for r in results_comparison]

p2 = bar(
    labels,
    [before_probs after_probs],
    bar_width=0.6,
    title="Сравнение вероятности успеха атаки",
    xlabel="Изолированный узел",
    ylabel="Вероятность успеха (%)",
    label=["До изоляции" "После изоляции"]
)

savefig(p2, plotsdir("defense_probability_comparison.png"))
println("График сравнения вероятностей сохранён в ", plotsdir("defense_probability_comparison.png"))

# График 3: Снижение вероятности в процентах
reductions = [r.reduction for r in results_comparison]

p3 = bar(
    labels,
    reductions,
    color=:green,
    title="Эффективность изоляции (снижение вероятности)",
    xlabel="Изолированный узел",
    ylabel="Снижение вероятности (%)",
    legend=false
)

savefig(p3, plotsdir("defense_reduction.png"))
println("График эффективности сохранён в ", plotsdir("defense_reduction.png"))

# ============================================
# Выводы и рекомендации
# ============================================

println("\n" * "=" ^ 70)
println("ВЫВОДЫ И РЕКОМЕНДАЦИИ")
println("=" ^ 70)

if !isempty(likely_path_isolated)
    println("""
1. Анализ показал, что изоляция критических узлов значительно снижает
   количество возможных путей атаки и вероятность успеха.

2. Наиболее эффективной оказалась изоляция узла $(most_critical):
   - Снижение количества путей: $(length(paths)) → $(length(paths_isolated))
   - Снижение вероятности: $(round(probability * 100, digits=1))% → $(round(prob_isolated * 100, digits=1))%
   - Общее снижение: $(round(reduction_total, digits=1))%

3. Рекомендации по защите:
   - Изолировать или усилить защиту узла $(most_critical)
   - Внедрить IDS/IPS на критических узлах
   - Усилить аутентификацию на узлах с высоким PageRank
   - Проводить регулярный мониторинг путей атаки
""")
else
    println("""
1. Анализ показал, что изоляция критических узлов полностью блокирует
   возможность достижения цели атаки.

2. Наиболее эффективной оказалась изоляция узла $(most_critical):
   - Пути атаки полностью устранены
   - Вероятность успеха снижена до 0%

3. Рекомендации по защите:
   - Обязательно изолировать узел $(most_critical)
   - Внедрить многофакторную аутентификацию
   - Проводить регулярный аудит безопасности
""")
end

