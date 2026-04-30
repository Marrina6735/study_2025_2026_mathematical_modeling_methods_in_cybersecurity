using DrWatson
@quickactivate "project"
using Graphs, Plots, JLD2, CSV, DataFrames, Random, Statistics
using GraphRecipes  

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

# ============================================
# Реальная корпоративная сеть
# ============================================

function create_corporate_network()
    # Описание узлов:
    # 1: Внешний атакующий (Интернет)
    # 2: Межсетевой экран (Firewall)
    # 3: Web-сервер (DMZ)
    # 4: Сервер БД (Database)
    # 5: Рабочая станция сотрудника
    # 6: Файловый сервер
    # 7: Почтовый сервер
    # 8: Административная станция
    # 9: Сервер резервного копирования
    # 10: Целевые секретные данные
    
    g = SimpleDiGraph(10)
    
    # Рёбра на основе реальных связей
    edges_list = [
        (1, 2),   # Атакующий -> FW
        (2, 3),   # FW -> Web-сервер
        (3, 4),   # Web-сервер -> БД
        (4, 10),  # БД -> Цель
        (3, 7),   # Web-сервер -> Почта
        (7, 5),   # Почта -> Рабочая станция
        (5, 6),   # Рабочая станция -> Файловый сервер
        (6, 9),   # Файловый сервер -> Резервное копирование
        (8, 4),   # Админ -> БД
        (8, 6),   # Админ -> Файловый сервер
        (8, 9),   # Админ -> Резервное копирование
        (5, 8),   # Рабочая станция -> Админ (повышение привилегий)
    ]
    
    for (u, v) in edges_list
        add_edge!(g, u, v)
    end
    
    return g
end

function get_cvss_scores()
    return Dict(
        (1,2) => 0.3,   # Обход FW - сложно
        (2,3) => 0.8,   # Эксплойт Web-сервера
        (3,4) => 0.7,   # SQL-инъекция
        (4,10) => 0.9,  # Доступ к секретным данным
        (3,7) => 0.6,   # Компрометация почты
        (7,5) => 0.5,   # Фишинг
        (5,6) => 0.4,   # Доступ к файлам
        (6,9) => 0.3,   # Доступ к бэкапам
        (8,4) => 0.95,  # Админский доступ к БД
        (8,6) => 0.95,  # Админский доступ к файлам
        (8,9) => 0.9,   # Админский доступ к бэкапам
        (5,8) => 0.2,   # Повышение привилегий
    )
end

# ============================================
# Основной код
# ============================================

println("=" ^ 70)
println("АНАЛИЗ РЕАЛЬНОЙ КОРПОРАТИВНОЙ СЕТИ")
println("=" ^ 70)

# Создание графа
g = create_corporate_network()
cvss_scores = get_cvss_scores()

# Параметры
source = 1    # Внешний атакующий
target = 10   # Секретные данные

# Названия узлов
node_names = Dict(
    1 => "Атакующий",
    2 => "FW",
    3 => "Web-сервер",
    4 => "БД",
    5 => "Раб.станция",
    6 => "Файл.сервер",
    7 => "Почта",
    8 => "Админ",
    9 => "Бэкап",
    10 => "ЦЕЛЬ",
)

println("\n" * "-" ^ 70)
println("ТОПОЛОГИЯ СЕТИ")
println("-" ^ 70)

for i in 1:nv(g)
    println("  ", i, ": ", node_names[i])
end

println("\nСвязи между узлами:")
for e in edges(g)
    u, v = src(e), dst(e)
    prob = get(cvss_scores, (u, v), 0.5)
    println("  ", node_names[u], " (", u, ") → ", node_names[v], " (", v, ") : вероятность = ", prob)
end

# ============================================
# Поиск путей атаки
# ============================================

println("\n" * "-" ^ 70)
println("ПОИСК ПУТЕЙ АТАКИ")
println("-" ^ 70)

paths = find_all_paths(g, source, target)
println("Найдено путей атаки от атакующего к цели: ", length(paths))

if !isempty(paths)
    println("\nВсе пути атаки:")
    for (i, path) in enumerate(paths)
        named_path = [node_names[p] for p in path]
        print("  Путь ", i, ": ")
        for (j, node) in enumerate(named_path)
            print(node)
            if j < length(named_path)
                print(" → ")
            end
        end
        println()
    end
end

# ============================================
# Наиболее вероятный путь
# ============================================

println("\n" * "-" ^ 70)
println("НАИБОЛЕЕ ВЕРОЯТНЫЙ ПУТЬ")
println("-" ^ 70)

likely_path, probability = most_likely_path(g, source, target, cvss_scores)

if !isempty(likely_path)
    println("\nНаиболее вероятный путь атаки:")
    named_path = [node_names[p] for p in likely_path]
    for (j, node) in enumerate(named_path)
        print(node)
        if j < length(named_path)
            print(" → ")
        end
    end
    println()
    println("\nВероятность успеха: ", round(probability * 100, digits=2), "%")
    
    # Вычисляем вероятности для каждого шага
    println("\nВероятности по шагам:")
    for j in 1:(length(likely_path)-1)
        u, v = likely_path[j], likely_path[j+1]
        prob_step = get(cvss_scores, (u, v), 0.5)
        println("  ", j, ". ", node_names[u], " → ", node_names[v], ": ", round(prob_step * 100, digits=1), "%")
    end
else
    println("Путь не найден")
end

# ============================================
# Метрики центральности
# ============================================

println("\n" * "-" ^ 70)
println("МЕТРИКИ ЦЕНТРАЛЬНОСТИ")
println("-" ^ 70)

# Вычисляем метрики
in_deg = indegree(g)
out_deg = outdegree(g)
pagerank = compute_pagerank(g)

println("\nУзлы с наибольшей входящей степенью (часто атакуемые):")
top_indeg = sortperm(in_deg, rev=true)[1:min(5, nv(g))]
for (rank, node) in enumerate(top_indeg)
    println("  ", rank, ". ", node_names[node], " (", node, "): ", in_deg[node], " входящих связей")
end

println("\nУзлы с наибольшим PageRank (глобально важные):")
top_pr = sortperm(pagerank, rev=true)[1:min(5, nv(g))]
for (rank, node) in enumerate(top_pr)
    println("  ", rank, ". ", node_names[node], " (", node, "): ", round(pagerank[node], digits=4))
end

# ============================================
# Анализ узлов на пути атаки
# ============================================

println("\n" * "-" ^ 70)
println("КРИТИЧЕСКИЕ УЗЛЫ НА ПУТИ АТАКИ")
println("-" ^ 70)

if !isempty(likely_path)
    println("\nУзлы, входящие в наиболее вероятный путь атаки:")
    for node in likely_path
        println("  - ", node_names[node], " (", node, "): in-degree = ", in_deg[node], ", PageRank = ", round(pagerank[node], digits=4))
    end
end

# ============================================
# Визуализация
# ============================================

println("\n" * "-" ^ 70)
println("ВИЗУАЛИЗАЦИЯ")
println("-" ^ 70)

mkpath(plotsdir())

# Нормализация PageRank для цвета
if maximum(pagerank) > minimum(pagerank)
    norm_rank = (pagerank .- minimum(pagerank)) ./ (maximum(pagerank) - minimum(pagerank))
else
    norm_rank = fill(0.5, nv(g))
end

# Создаём массив цветов для узлов
node_color = [cgrad(:RdYlGn, rev=true)[norm_rank[i]] for i in 1:nv(g)]
node_labels = [node_names[i] for i in 1:nv(g)]

# Простая визуализация через graphplot
try
    p1 = graphplot(
        g,
        nodeshape=:circle,
        curves=false,
        linecolor=:lightgray,
        linewidth=1,
        nodecolor=node_color,
        nodelabel=node_labels,
        title="Реальная корпоративная сеть (цвет = PageRank)",
        size=(900, 700),
        fontsize=8,
    )
    savefig(p1, plotsdir("real_network_graph.png"))
    println("График сохранён в ", plotsdir("real_network_graph.png"))
catch e
    println("Предупреждение: не удалось создать график: ", e)
end

# ============================================
# Сохранение результатов
# ============================================

println("\n" * "-" ^ 70)
println("СОХРАНЕНИЕ РЕЗУЛЬТАТОВ")
println("-" ^ 70)

results = Dict(
    :graph => g,
    :paths => paths,
    :likely_path => likely_path,
    :probability => probability,
    :in_degree => in_deg,
    :pagerank => pagerank,
    :node_names => node_names,
)

mkpath(datadir("real_network"))
@save datadir("real_network", "real_network_results.jld2") results
println("Результаты сохранены в ", datadir("real_network", "real_network_results.jld2"))

# Сохранение в CSV
df = DataFrame(
    Node = [node_names[i] for i in 1:nv(g)],
    Node_ID = 1:nv(g),
    In_Degree = in_deg,
    Out_Degree = out_deg,
    PageRank = pagerank,
    On_Likely_Path = [i in likely_path for i in 1:nv(g)]
)

CSV.write(datadir("real_network", "network_analysis.csv"), df)
println("CSV файл сохранён в ", datadir("real_network", "network_analysis.csv"))

