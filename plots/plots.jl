using CSV
using DataFrames
using Dates
using ScientificTypes
using Statistics
using CairoMakie

df = CSV.read("../data/partial/weather/austin.csv", DataFrame)

df.date = Date.(df.date)

# fig = Figure(size = (700, 700))

# ax = Axis(
#     fig[1,1], 
#     title = "Rozkład temperatury maksymalnej i minimalnej w czasie",
#     xlabel = "Data",
#     ylabel = "Temperatura",
# )

# lines!(ax, df.date, df.max_temp, label = "MAX", color = "#DB3B0F")
# lines!(ax, df.date, df.min_temp, label = "MIN", color = "#56C3DB")
# axislegend(ax)
# save("Wykres temperatury.svg", fig) 

# fig

fig = Figure(size = (700, 700))

ax = Axis(
    fig[1,1], 
    title = "Zależność maksymalnej temperatury od wiatru",
    xlabel = "Temperatura maksymalna",
    ylabel = "Prędkość wiatru",
)
density!(ax, df.snowfall)

save("Wykres temperatury do prędkości wiatru.svg", fig)

fig