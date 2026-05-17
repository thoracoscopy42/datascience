using MLJ
using ScientificTypes

include("../model_runner.jl")
include("../models/linear_regression.jl")

config = (
    region = "austin",

    weather_path = "data/partial/weather/austin.csv",
    energy_path = "data/partial/energy/austin.csv",

    target = :scent_daily,

    use_calendar_features = true,

    features = [
        :precipitation,
        :wind_speed,
        :snowfall,
        :max_temp,
        :min_temp,
        :month,
        :dayofweek,
        :is_weekend
    ],

    train_ratio = 0.67,

    output_path = "data/processed/modeling/austin_linear_regression_results.csv"
)

models = [
    ("Linear regression", build_linear_regression())
]

results = run_region_models(config, models)

println(results)