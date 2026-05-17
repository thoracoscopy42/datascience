using CSV
using DataFrames
using Dates
using MLJ

include("features.jl")
include("metrics.jl")

function load_region_dataset(config)
    
    weather = CSV.read(config.weather_path, DataFrame)
    energy = CSV.read(config.energy_path, DataFrame)

    weather.date = Date.(weather.date)
    energy.date = Date.(energy.date)

    df = innerjoin(
        weather,
        select(energy, :date, config.target),
        on = :date
    )

    sort!(df, :date)

    return df
end

function train_single_model(model_name::String, model, X_train, y_train, X_test, y_test)

    mach = machine(model, X_train, y_train)

    fit!(mach, verbosity = 0)

    y_pred = predict(mach, X_test)

    report = regression_report(y_test, y_pred)

    return (
            model = model_name,
            MAE = report.MAE,
            RMSE = report.RMSE,
            MAPE = report.MAPE,
            R2 = report.R2,
            machine = mach,
            y_test = y_test,
            y_pred = y_pred
        )
end

function run_region_models(config, models)

    df = load_region_dataset(config)

    if config.use_calendar_features
        add_calendar_features!(df)
    end

    model_df = prepare_model_frame!(
        df;
        target = config.target,
        features = config.features
    )

    println("Schema danych modelowych dla regionu: ", config.region)
    println(schema(model_df))

    X, y = split_xy(model_df; target = config.target)

    split = split_data_for_regression(
        X,
        y;
        train_ratio = config.train_ratio
    )

    results = []

    for (model_name, model) in models

        println("Trenuję model: ", model_name)

        result = train_single_model(
            model_name,
            model,
            split.X_train,
            split.y_train,
            split.X_test,
            split.y_test
        )

        push!(results, result)
    end

    results_df = DataFrame(
        region = fill(config.region, length(results)),
        model = [r.model for r in results],
        MAE = [r.MAE for r in results],
        RMSE = [r.RMSE for r in results],
        MAPE = [r.MAPE for r in results],
        R2 = [r.R2 for r in results]
    )

    mkpath(dirname(config.output_path))
    CSV.write(config.output_path, results_df)

    return results_df
end