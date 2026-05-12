using CSV
using DataFrames
using Dates

include("preprocessing_helpers.jl")

# input

df_ze = loader("dane pierwotne/zapotrzebowanie energetyczne.csv")
df_pp = loader("dane pierwotne/pomiary pogodowe.csv")

# wstępny preprocessing

rename!(df_ze, lowercase.(names(df_ze)))
if "hour ending" in names(df_ze)
    rename!(df_ze, "hour ending" => "datetime")
end
rename!(df_pp, lowercase.(names(df_pp)))
dropmissing!(df_pp)

df_ze.datetime = DateTime.(df_ze.datetime, dateformat"mm/dd/yyyy HH:MM")

names(df_ze)

columns = [
            :coast, 
            :east,
            :fwest,
            :north,
            :ncent,
            :south,
            :scent,
            :west,
            :ercot]

for col in columns
    df_ze[!, col] = parse_numbers.(df_ze[!, col])
end
df_ze