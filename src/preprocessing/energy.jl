using CSV
using DataFrames
using Dates
using ScientificTypes
using Statistics

include("helpers.jl")

df = loader("data/raw/energy.csv")

rename!(df, lowercase.(names(df)))
rename!(df, "hour ending" => "date")

relevant_cols = [:date, :coast, :north, :scent, :ercot]
select!(df, relevant_cols)

df.date = DateTime.(df.date, dateformat"mm/dd/yyyy HH:MM")
df.date = Date.(df.date)

columns = [:coast, :north, :scent, :ercot]

for col in columns
    df[!, col] = parse_numbers.(df[!,col])
end

#!SECTION - TODO 
# HOUSTON - COAST
# DALLAS - NORTH
# AUSTIN - SCENT
# SAN ANTONIO - SCENT
# ercot jako dodatkowa miara - zmienna opisywana dla drugiego zestawu modeli


df = agregate_distribute(df)

df



# CSV.write("data/processed/energy.csv", df)

