using DrWatson
@quickactivate "project"
using Graphs, JLD2, Statistics, Plots

# ============================================
# Функции для вычисления метрик центральности
# ============================================

"""
Вычисление PageRank (простая реализация)
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
                # Телепортация из узлов без исходящих рёбер
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
Вычисление betweenness centrality (упрощённая версия)
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

println("СРАВНЕНИЕ МЕТРИК ЦЕНТРАЛЬНОСТИ")

# ============================================
# Таблица метрик для всех узлов
# ============================================

println("ТАБЛИЦА МЕТРИК ДЛЯ ВСЕХ УЗЛОВ")
println("Узел | In-degree | Out-degree | Betweenness | PageRank | Closeness")

for i in 1:nv(g)
    println(rpad(i, 5), "| ", 
            rpad(metrics[:in_degree][i], 10), "| ", 
            rpad(metrics[:out_degree][i], 11), "| ",
            rpad(round(metrics[:betweenness][i], digits=2), 11), "| ",
            rpad(round(metrics[:pagerank][i], digits=4), 9), "| ",
            round(metrics[:closeness][i], digits=4))
end

# ============================================
# Топ-5 узлов по каждой метрике
# ============================================

println("ТОП-5 УЗЛОВ ПО КАЖДОЙ МЕТРИКЕ")

# In-degree
top_indeg = sortperm(metrics[:in_degree], rev=true)[1:min(5, nv(g))]
println("\nТоп-5 по входящей степени (in-degree):")
for (rank, node) in enumerate(top_indeg)
    println("  ", rank, ". Узел ", node, ": ", metrics[:in_degree][node], " входящих связей")
end

# Out-degree
top_outdeg = sortperm(metrics[:out_degree], rev=true)[1:min(5, nv(g))]
println("\nТоп-5 по исходящей степени (out-degree):")
for (rank, node) in enumerate(top_outdeg)
    println("  ", rank, ". Узел ", node, ": ", metrics[:out_degree][node], " исходящих связей")
end

# PageRank
top_pr = sortperm(metrics[:pagerank], rev=true)[1:min(5, nv(g))]
println("\nТоп-5 по PageRank:")
for (rank, node) in enumerate(top_pr)
    println("  ", rank, ". Узел ", node, ": ", round(metrics[:pagerank][node], digits=4))
end

# Betweenness
top_betw = sortperm(metrics[:betweenness], rev=true)[1:min(5, nv(g))]
println("\nТоп-5 по betweenness (посредничеству):")
for (rank, node) in enumerate(top_betw)
    println("  ", rank, ". Узел ", node, ": ", round(metrics[:betweenness][node], digits=2))
end

# Closeness
top_close = sortperm(metrics[:closeness], rev=true)[1:min(5, nv(g))]
println("\nТоп-5 по closeness (близости):")
for (rank, node) in enumerate(top_close)
    println("  ", rank, ". Узел ", node, ": ", round(metrics[:closeness][node], digits=4))
end

# ============================================
# Корреляция между метриками
# ============================================

println("КОРРЕЛЯЦИЯ МЕЖДУ МЕТРИКАМИ")

# Вычисляем корреляции
corr_in_pr = cor(metrics[:in_degree], metrics[:pagerank])
corr_out_pr = cor(metrics[:out_degree], metrics[:pagerank])
corr_in_betw = cor(metrics[:in_degree], metrics[:betweenness])
corr_pr_betw = cor(metrics[:pagerank], metrics[:betweenness])

println("\n| Метрики | Корреляция | Интерпретация |")
println("|---------|------------|---------------|")

# Определяем интерпретацию
if corr_in_pr > 0.7
    interp_in_pr = "Сильная положительная"
elseif corr_in_pr > 0.3
    interp_in_pr = "Средняя положительная"
else
    interp_in_pr = "Слабая"
end

if corr_out_pr > 0.7
    interp_out_pr = "Сильная положительная"
elseif corr_out_pr > 0.3
    interp_out_pr = "Средняя положительная"
else
    interp_out_pr = "Слабая"
end

if corr_in_betw > 0.7
    interp_in_betw = "Сильная положительная"
elseif corr_in_betw > 0.3
    interp_in_betw = "Средняя положительная"
else
    interp_in_betw = "Слабая"
end

if corr_pr_betw > 0.7
    interp_pr_betw = "Сильная положительная"
elseif corr_pr_betw > 0.3
    interp_pr_betw = "Средняя положительная"
else
    interp_pr_betw = "Слабая"
end

println("| In-degree vs PageRank | ", round(corr_in_pr, digits=4), " | ", interp_in_pr, " |")
println("| Out-degree vs PageRank | ", round(corr_out_pr, digits=4), " | ", interp_out_pr, " |")
println("| In-degree vs Betweenness | ", round(corr_in_betw, digits=4), " | ", interp_in_betw, " |")
println("| PageRank vs Betweenness | ", round(corr_pr_betw, digits=4), " | ", interp_pr_betw, " |")

# ============================================
# Анализ критических узлов
# ============================================

println("ВЫЯВЛЕНИЕ КРИТИЧЕСКИХ УЗЛОВ")

# Функция для нахождения пересечения топ-N узлов по разным метрикам
function find_critical_nodes(metrics, n=3)
    top_indeg = Set(sortperm(metrics[:in_degree], rev=true)[1:n])
    top_pr = Set(sortperm(metrics[:pagerank], rev=true)[1:n])
    top_betw = Set(sortperm(metrics[:betweenness], rev=true)[1:n])
    
    intersection = intersect(top_indeg, top_pr, top_betw)
    union_all = union(top_indeg, top_pr, top_betw)
    
    return intersection, union_all
end

critical, important = find_critical_nodes(metrics, 3)

println("\nКРИТИЧЕСКИЕ УЗЛЫ (в топ-3 по всем метрикам):")
if isempty(critical)
    println("   Нет узлов, входящих во все три топ-3 списка")
else
    for node in critical
        println("   Узел ", node, ":")
        println("      - In-degree: ", metrics[:in_degree][node])
        println("      - PageRank: ", round(metrics[:pagerank][node], digits=4))
        println("      - Betweenness: ", round(metrics[:betweenness][node], digits=2))
    end
end

println("\nВАЖНЫЕ УЗЛЫ (в топ-3 хотя бы по одной метрике):")
for node in important
    if node ∉ critical
        println("   Узел ", node)
    end
end

# ============================================
# Визуализация
# ============================================

println("ВИЗУАЛИЗАЦИЯ")

# Создаём подграфики для сравнения метрик
fig1 = plot(
    1:nv(g),
    metrics[:in_degree],
    marker=:circle,
    title="In-degree",
    xlabel="Узел",
    ylabel="Степень",
    legend=false,
)

fig2 = plot(
    1:nv(g),
    metrics[:pagerank],
    marker=:square,
    title="PageRank",
    xlabel="Узел",
    ylabel="Значение",
    legend=false,
)

fig3 = plot(
    1:nv(g),
    metrics[:betweenness],
    marker=:diamond,
    title="Betweenness",
    xlabel="Узел",
    ylabel="Значение",
    legend=false,
)

fig4 = plot(
    1:nv(g),
    metrics[:closeness],
    marker=:hexagon,
    title="Closeness",
    xlabel="Узел",
    ylabel="Значение",
    legend=false,
)

# Объединяем в один график 2×2
combined = plot(fig1, fig2, fig3, fig4, layout=(2, 2), size=(900, 700))
mkpath(plotsdir())
savefig(combined, plotsdir("metrics_comparison.png"))
println("\nГрафик метрик сохранён в ", plotsdir("metrics_comparison.png"))

# Scatter plot корреляции
fig_corr = scatter(
    metrics[:in_degree],
    metrics[:pagerank],
    marker=:circle,
    xlabel="In-degree",
    ylabel="PageRank",
    title="Корреляция между In-degree и PageRank",
    label="Узлы",
    markersize=6,
)

# Добавляем линию регрессии
coeff = cor(metrics[:in_degree], metrics[:pagerank]) * std(metrics[:pagerank]) / std(metrics[:in_degree])
intercept = mean(metrics[:pagerank]) - coeff * mean(metrics[:in_degree])
x_range = range(minimum(metrics[:in_degree]), maximum(metrics[:in_degree]), length=100)
plot!(fig_corr, x_range, intercept .+ coeff .* x_range, linewidth=2, linestyle=:dash, label="Линия регрессии")

savefig(fig_corr, plotsdir("in_degree_vs_pagerank.png"))
println("График корреляции сохранён в ", plotsdir("in_degree_vs_pagerank.png"))

# ============================================
# Итоговые выводы
# ============================================

println("ВЫВОДЫ ПО СРАВНЕНИЮ МЕТРИК")

# Определяем силу корреляции для вывода
if corr_in_pr > 0.7
    corr_strength = "Сильная"
elseif corr_in_pr > 0.3
    corr_strength = "Умеренная"
else
    corr_strength = "Слабая"
end

println("""
1. In-degree (входящая степень) показывает, какие узлы чаще всего являются 
   ЦЕЛЬЮ атак. Чем выше in-degree, тем уязвимее узел.

2. PageRank учитывает не только количество, но и ВАЖНОСТЬ атакующих узлов.
   Узел с высоким PageRank является критическим в глобальной структуре графа.

3. Betweenness (посредничество) показывает узлы, которые служат МОСТАМИ 
   между различными частями сети. Их изоляция может нарушить цепочки атак.

4. Closeness (близость) показывает узлы, которые могут БЫСТРО заразить другие узлы.

5. КОРРЕЛЯЦИЯ между метриками: """, corr_strength, """ связь между in-degree 
   и PageRank указывает, что популярные узлы также являются важными в глобальном масштабе.

6. Для эффективной защиты следует:
   - Мониторить узлы с высоким in-degree (часто атакуемые)
   - Изолировать узлы с высоким betweenness (критические мосты)
   - Усилить защиту узлов с высоким PageRank (глобально важные)
""")

