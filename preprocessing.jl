using CSV
using DataFrames
using Dates
using ScientificTypes

include("preprocessing_helpers.jl")
include("dictionaries/flagi_lokacje.jl")

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


columns = [:coast, :east, :fwest, :north, :ncent, :south, :scent, :west, :ercot]

for col in columns
    df_ze[!, col] = parse_numbers.(df_ze[!, col])
end

df_pp.awnd_trace = [get(trace_dict, String(x), false)      for x in df_pp.awnd_attributes]
df_pp.prcp_trace = [get(trace_dict, String(x), false)      for x in df_pp.prcp_attributes]
df_pp.snow_trace = [get(trace_dict, String(x), false)      for x in df_pp.snow_attributes]
df_pp.location   = [get(location_dict, String(x), missing) for x in df_pp.name]    

#usunięcie kolumn  
cols_to_delete_pp = [:awnd_attributes, :tmax_attributes, :tmin_attributes, :prcp_attributes, :snow_attributes, :name, :station, :latitude, :longitude, :elevation]
select!(df_pp, Not(cols_to_delete_pp))

# standaryzacja nazw
rename!(df_pp, "awnd" => "wind_speed")
rename!(df_pp, "prcp" => "precipitation")
rename!(df_pp, "snow" => "snowfall")

rename!(df_pp, "awnd_trace" => "t_wind_speed")
rename!(df_pp, "prcp_trace" => "t_precipitation")
rename!(df_pp, "snow_trace" => "t_snowfall")

rename!(df_pp, "tmax" => "max_temp")
rename!(df_pp, "tmin" => "min_temp")

#zmiana kolejności


#!SECTION - TODO 
# HUSTON - COAST
# DALLAS - NORTH
# AUSTIN - SCENT
# SAN ANTONIO - SCENT
# ew. ercot jako dodatkowa miara, lub w ogóle zmienna opisywana






select!(df_pp, [:date, :location, :precipitation, :t_precipitation, :wind_speed, :t_wind_speed, :snowfall, :t_snowfall, :max_temp, :min_temp])

# zapis
# CSV.write("dane przetworzone/pomiary pogodowe.csv", df_pp)
# CSV.write("dane przetworzone/zapotrzebowanie energetyczne.csv", df_ze)
