using CSV
using DataFrames
using Dates
using ScientificTypes
using Statistics

include("helpers.jl")
include("../../data/dictionaries/binary_flags.jl")
include("../../data/dictionaries/locations.jl")


df = loader("data/raw/weather.csv")


rename!(df, lowercase.(names(df)))

# to jeszcze nie wiem
df.awnd_attributes = coalesce.(df.awnd_attributes, "")
df.prcp_attributes = coalesce.(df.prcp_attributes, "")

df.prcp = coalesce.(df.prcp, 0.0)
df.awnd = coalesce.(df.awnd, 0.0)


# flagi trace
df.awnd_trace = [get(trace_dict, String(x), false) for x in df.awnd_attributes]
df.prcp_trace = [get(trace_dict, String(x), false) for x in df.prcp_attributes]
df.snow_trace = [get(trace_dict, String(x), false) for x in df.snow_attributes]

# lokalizacja na podstawie nazwy stacji
df.location = [get(location_dict, String(x), missing) for x in df.name]

# usunięcie kolumn technicznych
cols_to_delete = [
    :awnd_attributes,
    :tmax_attributes,
    :tmin_attributes,
    :prcp_attributes,
    :snow_attributes,
    :name,
    :station,
    :latitude,
    :longitude,
    :elevation
]

select!(df, Not(cols_to_delete))

# standaryzacja nazw
rename!(df, "awnd" => "wind_speed")
rename!(df, "prcp" => "precipitation")
rename!(df, "snow" => "snowfall")

rename!(df, "awnd_trace" => "t_wind_speed")
rename!(df, "prcp_trace" => "t_precipitation")
rename!(df, "snow_trace" => "t_snowfall")

rename!(df, "tmax" => "max_temp")
rename!(df, "tmin" => "min_temp")

# zmiana kolejności kolumn
column_order = [ :date, :location, :precipitation, :t_precipitation, :wind_speed, :t_wind_speed, :snowfall, :t_snowfall, :max_temp, :min_temp ]

select!(df, column_order)


agregate_region(df) 


# CSV.write("data/processed/weather.csv", df)
