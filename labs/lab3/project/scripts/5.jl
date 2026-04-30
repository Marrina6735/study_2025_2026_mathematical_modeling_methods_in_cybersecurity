using DrWatson
@quickactivate "project"
using Graphs, JLD2, Plots, Statistics, Random

# ============================================
# Функции для работы с графом 
# ============================================

"""
Вычисление междупутья (betweenness centrality) - упрощённая версия
"""
function compute_betweenness(g)
    n = nv(g)
    betweenness = zeros(n)
    
    for s in 1:n
        # BFS от узла s
        dist = fill(-1, n)
        dist[s] = 0
        queue = [s]
        paths_count = zeros(n)
        paths_count[s] = 1
        
        # Прямой проход
        while !isempty(queue)
            v = popfirst!(queue)
            for w in outneighbors(g, v)
                if dist[w] == -1
                    dist[w] = dist[v] + 1
                    push!(queue, w)
                end
                if dist[w] == dist[v] + 1
                    paths_count[w] += paths_count[v]
                end
            end
        end
        
        # Обратный проход
        dependency = zeros(n)
        nodes_by_dist = sortperm(dist, rev=true)
        
        for v in nodes_by_dist
            if dist[v] == -1
                continue
            end
            for w in outneighbors(g, v)
                if dist[w] == dist[v] + 1
                    dependency[v] += (paths_count[v] / paths_count[w]) * (1 + dependency[w])
                end
            end
            if v != s
                betweenness[v] += dependency[v]
            end
        end
    end
    
    return betweenness ./ 2
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
likely_path = data[:likely_path]

println("=" ^ 70)
println("ИНТЕРАКТИВНАЯ ВИЗУАЛИЗАЦИЯ ГРАФА АТАК")
println("=" ^ 70)

# ============================================
# Подготовка данных для визуализации
# ============================================

# Позиции узлов
n = nv(g)
Random.seed!(123)
pos_x = rand(n) * 10
pos_y = rand(n) * 10

# Нормализация PageRank для размера узлов
pagerank = metrics[:pagerank]
if maximum(pagerank) > minimum(pagerank)
    norm_size = 8 .+ 20 .* (pagerank .- minimum(pagerank)) ./ (maximum(pagerank) - minimum(pagerank))
else
    norm_size = fill(15, n)
end

# Цвета узлов на основе in-degree
indeg = metrics[:in_degree]
if maximum(indeg) > minimum(indeg)
    norm_color = (indeg .- minimum(indeg)) ./ (maximum(indeg) - minimum(indeg))
else
    norm_color = fill(0.5, n)
end
color_palette = cgrad(:RdYlGn, rev=true)

println("\n" * "-" ^ 70)
println("СТАТИСТИКА ГРАФА")
println("-" ^ 70)
println("Количество узлов: ", n)
println("Количество рёбер: ", ne(g))
println("Количество путей от 1 к 20: ", length(paths))
if !isempty(likely_path)
    path_str = join(likely_path, " → ")
    println("Наиболее вероятный путь: ", path_str)
    println("Вероятность: ", round(data[:probability] * 100, digits=2), "%")
end

# ============================================
# Визуализация 1: Граф с цветовой индикацией
# ============================================

println("\n" * "-" ^ 70)
println("ВИЗУАЛИЗАЦИЯ 1: СОЗДАНИЕ ГРАФА")
println("-" ^ 70)

# Создаём цвет для каждого узла
node_colors = [color_palette[norm_color[i]] for i in 1:n]

# Рисуем граф
p1 = plot(title="Граф атак (цвет = In-degree, размер = PageRank)", 
          size=(900, 700), legend=false)

# Рисуем рёбра
for e in edges(g)
    u, v = src(e), dst(e)
    # Проверяем, принадлежит ли ребро наиболее вероятному пути
    on_path = false
    if !isempty(likely_path)
        for j in 1:(length(likely_path)-1)
            if u == likely_path[j] && v == likely_path[j+1]
                on_path = true
                break
            end
        end
    end
    color = on_path ? :red : :lightgray
    width = on_path ? 3 : 1
    
    plot!(p1, [pos_x[u], pos_x[v]], [pos_y[u], pos_y[v]], 
          linecolor=color, linewidth=width, label="")
end

# Рисуем узлы
for i in 1:n
    is_on_path = !isempty(likely_path) && (i in likely_path)
    marker_color = is_on_path ? :red : node_colors[i]
    marker_size = is_on_path ? norm_size[i] + 3 : norm_size[i]
    
    scatter!(p1, [pos_x[i]], [pos_y[i]], 
             markersize=marker_size, 
             marker=:circle, 
             markercolor=marker_color,
             markerstrokewidth=1,
             markerstrokecolor=:black,
             label="")
    
    # Добавляем номер узла
    annotate!(p1, pos_x[i], pos_y[i] + 0.3, text(string(i), 8, :black))
end

# Добавляем легенду вручную
scatter!(p1, [NaN], [NaN], markersize=8, markercolor=:red, label="На пути атаки")
scatter!(p1, [NaN], [NaN], markersize=8, markercolor=:green, label="Низкая in-degree")
scatter!(p1, [NaN], [NaN], markersize=8, markercolor=:orange, label="Высокая in-degree")
scatter!(p1, [NaN], [NaN], markersize=4, markercolor=:black, label="Размер = PageRank")

mkpath(plotsdir())
savefig(p1, plotsdir("attack_graph_colored.png"))
println("График сохранён в ", plotsdir("attack_graph_colored.png"))

# ============================================
# Визуализация 2: Таблица с данными
# ============================================

println("\n" * "-" ^ 70)
println("ВИЗУАЛИЗАЦИЯ 2: ДЕТАЛЬНАЯ ТАБЛИЦА")
println("-" ^ 70)

println()
println("┌──────┬─────────────┬─────────────┬─────────────┬─────────────┬─────────────┐")
println("│ Узел │  In-degree  │  Out-degree │  PageRank   │ Betweenness │  Closeness  │")
println("├──────┼─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤")

for i in 1:n
    line = "│ " * rpad(string(i), 4) * 
           " │ " * rpad(string(round(metrics[:in_degree][i], digits=2)), 11) *
           " │ " * rpad(string(round(metrics[:out_degree][i], digits=2)), 11) *
           " │ " * rpad(string(round(metrics[:pagerank][i], digits=4)), 11) *
           " │ " * rpad(string(round(metrics[:betweenness][i], digits=2)), 11) *
           " │ " * rpad(string(round(metrics[:closeness][i], digits=4)), 11) * " │"
    println(line)
end
println("└──────┴─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘")

# ============================================
# Визуализация 3: Топ-5 по in-degree
# ============================================

println("\n" * "-" ^ 70)
println("ВИЗУАЛИЗАЦИЯ 3: ТОП-5 ПО ВХОДЯЩЕЙ СТЕПЕНИ")
println("-" ^ 70)

top_5_indeg = sortperm(metrics[:in_degree], rev=true)[1:min(5, n)]
indeg_values = [metrics[:in_degree][i] for i in top_5_indeg]

p2 = bar(indeg_values,
         orientation=:horizontal,
         bar_width=0.7,
         color=:steelblue,
         title="Топ-5 узлов по входящей степени (in-degree)",
         xlabel="In-degree",
         ylabel="Узел",
         legend=false,
         yticks=(1:length(top_5_indeg), [string(i) for i in top_5_indeg]),
         size=(500, 400))

savefig(p2, plotsdir("top_5_indeg.png"))
println("График топ-5 по in-degree сохранён в ", plotsdir("top_5_indeg.png"))

# ============================================
# Визуализация 4: Топ-5 по PageRank
# ============================================

println("\n" * "-" ^ 70)
println("ВИЗУАЛИЗАЦИЯ 4: ТОП-5 ПО PAGERANK")
println("-" ^ 70)

top_5_pr = sortperm(metrics[:pagerank], rev=true)[1:min(5, n)]
pr_values = [metrics[:pagerank][i] for i in top_5_pr]

p3 = bar(pr_values,
         orientation=:horizontal,
         bar_width=0.7,
         color=:coral,
         title="Топ-5 узлов по PageRank",
         xlabel="PageRank",
         ylabel="Узел",
         legend=false,
         yticks=(1:length(top_5_pr), [string(i) for i in top_5_pr]),
         size=(500, 400))

savefig(p3, plotsdir("top_5_pagerank.png"))
println("График топ-5 по PageRank сохранён в ", plotsdir("top_5_pagerank.png"))

# ============================================
# Визуализация 5: Пути атаки
# ============================================

println("\n" * "-" ^ 70)
println("ВИЗУАЛИЗАЦИЯ 5: ПУТИ АТАКИ")
println("-" ^ 70)

if !isempty(paths)
    # Ограничиваем количество отображаемых путей
    display_paths = length(paths) > 15 ? paths[1:15] : paths
    plot_height = max(400, length(display_paths) * 30)
    
    p4 = plot(title="Все пути атаки от узла 1 к узлу 20", 
              size=(600, plot_height), 
              legend=false,
              ylabel="Путь",
              xlabel="Шаг")
    
    for (i, path) in enumerate(display_paths)
        y_pos = length(display_paths) - i + 1
        x_positions = 1:length(path)
        y_positions = fill(y_pos, length(path))
        plot!(p4, x_positions, y_positions, marker=:circle, linewidth=2, label="")
        
        # Добавляем подписи узлов
        for (j, node) in enumerate(path)
            annotate!(p4, j, y_pos + 0.2, text(string(node), 7, :black))
        end
    end
    
    title!(p4, "Пути атаки от 1 к 20 (показаны первые $(length(display_paths)) из $(length(paths)))")
    
    savefig(p4, plotsdir("all_attack_paths.png"))
    println("График всех путей атаки сохранён в ", plotsdir("all_attack_paths.png"))
else
    println("Путей атаки не найдено")
end

# ============================================
# Визуализация 6: Корреляция метрик
# ============================================

println("\n" * "-" ^ 70)
println("ВИЗУАЛИЗАЦИЯ 6: КОРРЕЛЯЦИЯ МЕТРИК")
println("-" ^ 70)

p5 = scatter(metrics[:in_degree], metrics[:pagerank],
             markersize=8,
             marker=:circle,
             xlabel="In-degree",
             ylabel="PageRank",
             title="Корреляция между In-degree и PageRank",
             label="Узлы",
             legend=:bottomright)

# Добавляем линию регрессии
if std(metrics[:in_degree]) > 0 && std(metrics[:pagerank]) > 0
    coeff = cor(metrics[:in_degree], metrics[:pagerank]) * 
            std(metrics[:pagerank]) / std(metrics[:in_degree])
    intercept = mean(metrics[:pagerank]) - coeff * mean(metrics[:in_degree])
    x_range = range(minimum(metrics[:in_degree]), maximum(metrics[:in_degree]), length=100)
    plot!(p5, x_range, intercept .+ coeff .* x_range, 
          linewidth=2, linestyle=:dash, label="Линия регрессии")
end

savefig(p5, plotsdir("correlation_indeg_pagerank.png"))
println("График корреляции сохранён в ", plotsdir("correlation_indeg_pagerank.png"))

# ============================================
# Статистика и выводы
# ============================================

println("\n" * "=" ^ 70)
println("СТАТИСТИКА И ВЫВОДЫ")
println("=" ^ 70)

# Вычисляем корреляции
corr_in_pr = cor(metrics[:in_degree], metrics[:pagerank])
corr_in_betw = cor(metrics[:in_degree], metrics[:betweenness])
corr_pr_betw = cor(metrics[:pagerank], metrics[:betweenness])

println()
println("Корреляция между метриками:")
println("  In-degree vs PageRank: ", round(corr_in_pr, digits=4))
println("  In-degree vs Betweenness: ", round(corr_in_betw, digits=4))
println("  PageRank vs Betweenness: ", round(corr_pr_betw, digits=4))

# Вывод информации о наиболее вероятном пути
if !isempty(likely_path)
    println()
    println("Наиболее вероятный путь атаки:")
    for (i, node) in enumerate(likely_path)
        println("  Шаг ", i, ": Узел ", node, 
                " (in-degree=", metrics[:in_degree][node],
                ", PageRank=", round(metrics[:pagerank][node], digits=4), ")")
    end
end

# Определяем критические узлы
println()
println("Критические узлы (высокая центральность):")
critical_nodes = intersect(
    Set(sortperm(metrics[:in_degree], rev=true)[1:3]),
    Set(sortperm(metrics[:pagerank], rev=true)[1:3])
)

if isempty(critical_nodes)
    println("  Нет узлов, входящих в топ-3 по всем метрикам")
else
    for node in critical_nodes
        println("  Узел ", node, ":")
        println("    - In-degree: ", metrics[:in_degree][node])
        println("    - PageRank: ", round(metrics[:pagerank][node], digits=4))
        println("    - Betweenness: ", round(metrics[:betweenness][node], digits=2))
    end
end

println()
println("-" ^ 70)
println("ВСЕ ГРАФИКИ СОХРАНЕНЫ В ПАПКЕ plots/")
println("-" ^ 70)
println("  • attack_graph_colored.png - граф с цветовой индикацией")
println("  • top_5_indeg.png - топ-5 узлов по входящей степени")
println("  • top_5_pagerank.png - топ-5 узлов по PageRank")
if !isempty(paths)
    println("  • all_attack_paths.png - все пути атаки")
end
println("  • correlation_indeg_pagerank.png - корреляция метрик")

println()
println("✓ Визуализация завершена!")