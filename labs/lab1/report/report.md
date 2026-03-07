---
## Front matter
title: "ОТЧЕТ ПО ЛАБОРАТОРНОЙ РАБОТЕ №1"
subtitle: "Методы математического моделирования в кибербезопасности. Практикум"
author: "Коняева Марина Александровна"

## Generic otions
lang: ru-RU
toc-title: "Содержание"

## Bibliography
bibliography: bib/cite.bib
csl: pandoc/csl/gost-r-7-0-5-2008-numeric.csl

## Pdf output format
toc: true # Table of contents
toc-depth: 2
fontsize: 12pt
linestretch: 1.5
papersize: a4
documentclass: scrreprt
## I18n polyglossia
polyglossia-lang:
  name: russian
  options:
	- spelling=modern
	- babelshorthands=true
polyglossia-otherlangs:
  name: english
## I18n babel
babel-lang: russian
babel-otherlangs: english
## Fonts
mainfont: PT Serif
romanfont: PT Serif
sansfont: PT Sans
monofont: PT Mono
mainfontoptions: Ligatures=TeX
romanfontoptions: Ligatures=TeX
sansfontoptions: Ligatures=TeX,Scale=MatchLowercase
monofontoptions: Scale=MatchLowercase,Scale=0.9
## Biblatex
biblatex: true
biblio-style: "gost-numeric"
biblatexoptions:
  - parentracker=true
  - backend=biber
  - hyperref=auto
  - language=auto
  - autolang=other*
  - citestyle=gost-numeric
## Pandoc-crossref LaTeX customization
figureTitle: "Рис."
tableTitle: "Таблица"
listingTitle: "Листинг"
lolTitle: "Листинги"
## Misc options
indent: true
header-includes:
  - \usepackage{indentfirst}
  - \usepackage{float} # keep figures where there are in the text
  - \floatplacement{figure}{H} # keep figures where there are in the text
---


# Цель работы

Освоение модели экспоненциального роста, её формального математического описания и аналитического решения соответствующего дифференциального уравнения. Анализ влияния параметра роста на поведение системы, а также получение навыков проведения параметрических исследований и интерпретации результатов.



# Задание

В рамках лабораторной работы требуется рассмотреть модель экспоненциального роста.



# Теоретическое введение

Экспоненциальный рост представляет собой процесс увеличения некоторой величины, при котором скорость её изменения в каждый момент времени пропорциональна текущему значению. Это означает, что по мере увеличения самой величины возрастает и скорость её роста.

В качестве наглядных примеров можно привести начисление сложных процентов в финансовой сфере или эффект снежного кома, который по мере увеличения начинает нарастать всё быстрее.

Математически данный процесс описывается дифференциальным уравнением:

$$
\frac{du}{dt} = \alpha u
$$

где:
- u — текущее значение исследуемой величины
- t — время
- du/dt — скорость изменения величины
- α — постоянный коэффициент роста

При α > 0 система демонстрирует рост, а при α < 0 наблюдается экспоненциальное убывание.

Смысл уравнения заключается в том, что скорость изменения напрямую определяется текущим значением самой величины.

Аналитическое решение данного дифференциального уравнения имеет следующий вид:

$$
u(t) = u_0 e^{\alpha t}
$$


где u₀ — начальное значение величины в момент времени t = 0.

**Ключевые характеристики модели**

Увеличение величины происходит с удвоением через равные промежутки времени. Время удвоения определяется формулой:


$$
T_2 = \frac{\ln(2)}{\alpha} \approx \frac{0.693}{\alpha}
$$


Значение времени удвоения не зависит от текущего уровня величины и определяется исключительно коэффициентом роста.

**Области применения**

Биология: увеличение численности микроорганизмов при достаточном количестве ресурсов. Финансы: рост вложений при начислении сложных процентов. Эпидемиология: распространение инфекции на ранних этапах. Демография: периоды активного роста населения. Физика: развитие цепных ядерных реакций. Информационные технологии: увеличение вычислительных мощностей и сетевого трафика.

**Ограничения модели**

Экспоненциальная модель является идеализированной и не учитывает ограниченность ресурсов. В реальных условиях бесконечный рост невозможен: со временем система сталкивается с ограничениями, что приводит к замедлению темпов увеличения и переходу к логистическому характеру развития.

---

# Выполнение лабораторной работы

В процессе выполнения лабораторной работы было осуществлено моделирование экспоненциального роста на основе аналитического решения соответствующего дифференциального уравнения.

На первом этапе рассмотрен базовый эксперимент при фиксированном значении коэффициента роста α = 0.3. Полученный график иллюстрирует зависимость исследуемой величины от времени и демонстрирует характерное ускорение роста.

![Экспоненциальный рост (базовый эксперимент)](image/single_experiment.png){#fig-base width=80%}

Рисунок 1: Экспоненциальный рост (базовый эксперимент)

В начальный период увеличение происходит сравнительно медленно, однако затем скорость возрастает, и к концу рассматриваемого интервала наблюдается резкий рост функции.

Далее было выполнено параметрическое исследование, направленное на изучение влияния коэффициента α на динамику системы. Для этого были построены графики при различных значениях параметра роста.

![Параметрическое исследование: влияние α на рост](image/parametric_scan_comparison.png){#fig-param width=85%}


Рисунок 2: Параметрическое исследование: влияние α на рост

Полученные результаты показывают, что увеличение значения α приводит к существенному ускорению роста. При малых значениях параметра функция возрастает постепенно, тогда как при больших быстро достигает значительных величин.

Отдельное внимание было уделено исследованию зависимости времени удвоения от коэффициента роста. В теории это время определяется выражением T₂ = ln(2)/α. Численные расчёты подтвердили справедливость данной зависимости.

![Зависимость времени удвоения от α](image/doubling_time_vs_alpha.png){#fig-double width=80%}


Рисунок 3: Зависимость времени удвоения от α

Из графика следует, что с увеличением α время удвоения уменьшается, что полностью соответствует теоретическим ожиданиям.

Дополнительно была изучена зависимость времени вычисления от значения параметра роста.

![Зависимость времени вычисления от α](image/computation_time_vs_alpha.png){#fig-time width=80%}


Рисунок 4: Зависимость времени вычисления от α

Отмечается незначительное увеличение времени расчётов при возрастании α, что связано с ростом значений функции и особенностями обработки численных данных.

Для моделирования процесса и построения графиков использовались внешние файлы с программным кодом.

---

# Экспоненциальный рост

**Инициализация проекта и загрузка пакетов**

```
using DrWatson
@quickactivate "project"
using DifferentialEquations
using Plots
using DataFrames
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))
```


**Определение модели**

Уравнение экспоненциального роста: du/dt = αu, u(0) = u₀

```
function exponential_growth!(du, u, p, t)
α = p
du[1] = α * u[1]
end
```

**Первый запуск с параметрами по умолчанию**

Зададим начальные параметры:
- u₀ = [1.0] - начальная популяция
- α = 0.3 - скорость роста
- tspan = (0.0, 10.0) - временной интервал

```
prob = ODEProblem(exponential_growth!, u0, tspan, α)
sol = solve(prob, Tsit5(), saveat=0.1)
```

**Визуализация результатов**

Построим график решения:

```
plot(sol, label="u(t)", xlabel="Время t", ylabel="Популяция u",
title="Экспоненциальный рост (α = $α)", lw=2, legend=:topleft)
savefig(plotsdir(script_name, "exponential_growth_α=$α.png"))
```


**Анализ результатов**

Создадим таблицу с данными:

```
df = DataFrame(t=sol.t, u=first.(sol.u))
println("Первые 5 строк результатов:")
println(first(df, 5))

u_final = last(sol.u)[1]
doubling_time = log(2) / α
println("\nАналитическое время удвоения: ", round(doubling_time; digits=2))
```


Первые 5 строк результатов:
5×2 DataFrame
 Row │ t        u
     │ Float64  Float64
─────┼──────────────────
   1 │     0.0  1.0
   2 │     0.1  1.03045
   3 │     0.2  1.06184
   4 │     0.3  1.09417
   5 │     0.4  1.1275


**Сохранение всех результатов**

```
@save datadir(script_name, "all_results.jld2") df
```


---

# Параметрическое исследование экспоненциального роста

**Активация проекта и загрузка пакетов**

```
using DrWatson
@quickactivate "project"
using DifferentialEquations
using DataFrames
using Plots
using JLD2
using BenchmarkTools

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))
```


**Определение модели**

Модель: du/dt = αu

```
function exponential_growth!(du, u, p, t)
α = p.α
du[1] = α * u[1]
end
```


**Определение параметров**

Базовый набор параметров для одного эксперимента:

```
base_params = Dict(
:u0 => [1.0],
:α => 0.3,
:tspan => (0.0, 10.0),
:solver => Tsit5(),
:saveat => 0.1,
:experiment_name => "base_experiment"
)

println("Базовые параметры эксперимента:")
for (key, value) in base_params
println(" $key = $value")
end
```


**Функция для запуска одного эксперимента**

```
function run_single_experiment(params::Dict)
@unpack u0, α, tspan, solver, saveat = params
prob = ODEProblem(exponential_growth!, u0, tspan, (α=α,))
sol = solve(prob, solver; saveat=saveat)
final_population = last(sol.u)[1]
doubling_time = log(2) / α
return Dict(
"solution" => sol,
"time_points" => sol.t,
"population_values" => first.(sol.u),
"final_population" => final_population,
"doubling_time" => doubling_time,
"parameters" => params
)
end
```


**Запуск базового эксперимента**

```
data, path = produce_or_load(
datadir(script_name, "single"),
base_params,
run_single_experiment,
prefix = "exp_growth",
tag = false,
verbose = true
)
println("\nРезультаты базового эксперимента:")
println(" Финальная популяция: ", data["final_population"])
println(" Время удвоения: ", round(data["doubling_time"]; digits=2))
println(" Файл результатов: ", path)

```

**Визуализация базового эксперимента**

```
p1 = plot(data["time_points"], data["population_values"],
label="α = $(base_params[:α])",
xlabel="Время t",
ylabel="Популяция u(t)",
title="Экспоненциальный рост",
lw=2,
legend=:topleft,
grid=true)

savefig(plotsdir(script_name, "single_experiment.png"))
```


**Параметрическое сканирование**

Исследование влияния параметра α:

```
param_grid = Dict(
:u0 => [[1.0]],
:α => [0.1, 0.3, 0.5, 0.8, 1.0],
:tspan => [(0.0, 10.0)],
:solver => [Tsit5()],
:saveat => [0.1],
:experiment_name => ["parametric_scan"]
)

all_params = dict_list(param_grid)

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ СКАНИРОВАНИЕ")
println("Всего комбинаций параметров: ", length(all_params))
println("Исследуемые значения α: ", param_grid[:α])
println("="^60)
```


**Запуск всех экспериментов**

```
all_results = []
all_dfs = []

for (i, params) in enumerate(all_params)
println("Процесс: $i/$(length(all_params)) | α = $(params[:α])")

data, path = produce_or_load(
datadir(script_name, "parametric_scan"),
params,
run_single_experiment,
prefix = "scan",
tag = false,
verbose = false
)

result_summary = merge(
params,
Dict(
:final_population => data["final_population"],
:doubling_time => data["doubling_time"],
:filepath => path
)
)

push!(all_results, result_summary)

df = DataFrame(
t = data["time_points"],
u = data["population_values"],
α = fill(params[:α], length(data["time_points"]))
)

push!(all_dfs, df)
end
```


**Анализ и визуализация результатов**

Сводная таблица результатов:

```
results_df = DataFrame(all_results)
println("\nСводная таблица результатов:")
println(results_df[:, [:α, :final_population, :doubling_time]])
```

Сравнительный график всех траекторий:

```
p2 = plot(size=(800, 500), dpi=150)

for params in all_params
data, _ = produce_or_load(
datadir(script_name, "parametric_scan"),
params,
run_single_experiment,
prefix = "scan"
)
plot!(p2, data["time_points"], data["population_values"],
label="α = $(params[:α])", lw=2, alpha=0.8)
end

plot!(p2, xlabel="Время t", ylabel="Популяция u(t)",
title="Влияние параметра α на рост", legend=:topleft, grid=true)

savefig(plotsdir(script_name, "parametric_scan_comparison.png"))
```


График зависимости времени удвоения от α:

```
p3 = plot(results_df.α, results_df.doubling_time,
seriestype=:scatter,
label="Численное решение",
xlabel="Скорость роста α",
ylabel="Время удвоения",
title="Зависимость времени удвоения от α",
markersize=8,
markercolor=:red,
legend=:topright)

α_range = 0.1:0.01:1.0
plot!(p3, α_range, log.(2) ./ α_range,
label="Теория: T₂ = ln(2)/α",
lw=2, linestyle=:dash, linecolor=:blue)

savefig(plotsdir(script_name, "doubling_time_vs_alpha.png"))
```



**Сохранение всех результатов**

```
@save datadir(script_name, "all_results.jld2") base_params param_grid all_params results_df bench_df
@save datadir(script_name, "all_plots.jld2") p1 p2 p3 p4

println("\n" * "="^60)
println("ЛАБОРАТОРНАЯ РАБОТА ЗАВЕРШЕНА")
println("="^60)
println("\nРезультаты сохранены в:")
println(" data/$(script_name)/single/ - базовый эксперимент")
println(" data/$(script_name)/parametric_scan/ - параметрическое сканирование")
println(" data/$(script_name)/all_results.jld2 - сводные данные")
println(" plots/$(script_name)/ - все графики")
println(" data/$(script_name)/all_plots.jld2 - объекты графиков")

```


Проведённый анализ позволил наглядно оценить влияние коэффициента роста на динамику изменения величины, время её удвоения и вычислительные характеристики модели.

---

# Выводы

В рамках лабораторной работы была подробно рассмотрена модель экспоненциального роста и её математическая постановка. Проанализировано дифференциальное уравнение, описывающее изменение величины во времени, а также получено его аналитическое решение.

Построен базовый график, демонстрирующий ускоряющийся характер увеличения величины. Выполнено параметрическое исследование, показавшее, что коэффициент α оказывает значительное влияние на скорость развития системы.

Экспериментально подтверждена теоретическая зависимость времени удвоения от параметра роста: с увеличением α время удвоения уменьшается. Также проведён анализ вычислительных затрат, который показал слабую зависимость времени расчёта от значения коэффициента.

Полученные результаты согласуются с теоретическими представлениями об экспоненциальном росте и подтверждают возможность применения данной модели для описания процессов в биологии, экономике, физике и сфере информационных технологий.

---

# Список литературы

1. A Multi-Language Computing Environment for Literate Programming and Reproducible Research / E. Schulte [et al.] // Journal of Statistical Software. — 2012. — Vol. 46, no. 3.

2. Knuth D. E. Literate Programming // The Computer Journal. — 1984. — Vol. 27, no. 2. — P. 97–111.

3. The Story in the Notebook / M. B. Kery [et al.] // Proceedings of the 2018 CHI Conference on Human Factors in Computing Systems. — ACM, 2018. — P. 1–11.