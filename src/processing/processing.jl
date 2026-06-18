using CSV
using DataFrames
using Dates
using Statistics
using MLJ
using MLJLinearModels
using DecisionTree
using StableRNGs
using Random

const RESULTS_DIR = "data/processed/modeling"
const PREDICTIONS_DIR = joinpath(RESULTS_DIR, "predictions")

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels verbosity=0
RidgeRegressor = @load RidgeRegressor pkg=MLJLinearModels verbosity=0
DecisionTreeRegressor = @load DecisionTreeRegressor pkg=DecisionTree verbosity=0
RandomForestRegressor = @load RandomForestRegressor pkg=DecisionTree verbosity=0

# =========================
# Metryki
# =========================

function rmse_score(y, ŷ)
    return sqrt(mean((y .- ŷ).^2))
end

function mae_score(y, ŷ)
    return mean(abs.(y .- ŷ))
end

function r2_score(y, ŷ)
    ss_res = sum((y .- ŷ).^2)
    ss_tot = sum((y .- mean(y)).^2)

    if ss_tot == 0
        return NaN
    end

    return 1 - ss_res / ss_tot
end

# =========================
# Dane
# =========================

function normalize_location_name(location::String)
    return lowercase(replace(location, " " => "_"))
end

function read_location_data(location::String)
    loc = normalize_location_name(location)

    weather_path = joinpath("data", "partial", "weather", "$(loc).csv")
    energy_path = joinpath("data", "partial", "energy", "$(loc).csv")

    if !isfile(weather_path)
        error("Brak pliku pogodowego: $(weather_path)")
    end

    if !isfile(energy_path)
        error("Brak pliku energetycznego: $(energy_path)")
    end

    weather = CSV.read(weather_path, DataFrame)
    energy = CSV.read(energy_path, DataFrame)

    if :date ∉ Symbol.(names(weather))
        error("Brak kolumny date w pliku: $(weather_path)")
    end

    if :date ∉ Symbol.(names(energy))
        error("Brak kolumny date w pliku: $(energy_path)")
    end

    weather.date = Date.(weather.date)
    energy.date = Date.(energy.date)

    df = innerjoin(weather, energy, on=:date)
    dropmissing!(df)

    return df
end

function select_features(df::DataFrame, target::Symbol)
    excluded = Set([:date, :location, target])
    features = Symbol[]

    for name in names(df)
        col = Symbol(name)

        if col in excluded
            continue
        end

        if eltype(skipmissing(df[!, col])) <: Number
            push!(features, col)
        end
    end

    return features
end

function build_feature_matrix(df::DataFrame, features::Vector{Symbol})
    X = DataFrame()

    for feature in features
        X[!, feature] = Float64.(df[!, feature])
    end

    return X
end

function train_test_indices(n::Int; train_ratio=0.8)
    if n < 10
        error("Za mało obserwacji do podziału train/test: $(n)")
    end

    rng = StableRNG(42)
    idx = collect(1:n)
    shuffled = shuffle(rng, idx)

    train_size = floor(Int, train_ratio * n)

    train = shuffled[1:train_size]
    test = shuffled[(train_size + 1):end]

    return train, test
end

# =========================
# Ramki wynikowe
# =========================

function evaluate_prediction(location, target, model_name, y_test, y_pred, n_train, n_test)
    y_test_float = Float64.(y_test)
    y_pred_float = Float64.(y_pred)

    return DataFrame(
        location = [location],
        target = [String(target)],
        model = [model_name],
        mae = [mae_score(y_test_float, y_pred_float)],
        rmse = [rmse_score(y_test_float, y_pred_float)],
        r2 = [r2_score(y_test_float, y_pred_float)],
        n_train = [n_train],
        n_test = [n_test]
    )
end

function build_predictions_frame(location, target, model_name, dates, y_true, y_pred)
    pred_df = DataFrame(
        location = fill(location, length(y_true)),
        target = fill(String(target), length(y_true)),
        model = fill(model_name, length(y_true)),
        date = dates,
        actual = Float64.(y_true),
        predicted = Float64.(y_pred)
    )

    pred_df.residual = pred_df.actual .- pred_df.predicted
    pred_df.abs_error = abs.(pred_df.residual)

    sort!(pred_df, :date)

    return pred_df
end

# =========================
# Ewaluacja baseline
# =========================

function evaluate_mean_baseline(location, target, dates_test, y_train, y_test)
    y_pred = fill(mean(y_train), length(y_test))

    metrics_df = evaluate_prediction(
        location,
        target,
        "MeanBaseline",
        y_test,
        y_pred,
        length(y_train),
        length(y_test)
    )

    predictions_df = build_predictions_frame(
        location,
        target,
        "MeanBaseline",
        dates_test,
        y_test,
        y_pred
    )

    return metrics_df, predictions_df
end

# =========================
# Ewaluacja modeli MLJ
# =========================

function evaluate_mlj_model(location, target, model_name, model, X, y, dates, train, test)
    mach = MLJ.machine(model, X, y)
    MLJ.fit!(mach, rows=train, verbosity=0)

    y_pred = MLJ.predict(mach, rows=test)

    metrics_df = evaluate_prediction(
        location,
        target,
        model_name,
        y[test],
        y_pred,
        length(train),
        length(test)
    )

    predictions_df = build_predictions_frame(
        location,
        target,
        model_name,
        dates[test],
        y[test],
        y_pred
    )

    return metrics_df, predictions_df
end

# =========================
# Jedna lokalizacja
# =========================

function run_models_for_location(location::String, target::Symbol)
    df = read_location_data(location)

    if target ∉ Symbol.(names(df))
        error("Brak kolumny targetu $(target) dla lokalizacji $(location).")
    end

    features = select_features(df, target)

    if isempty(features)
        error("Brak cech numerycznych dla lokalizacji $(location).")
    end

    X = build_feature_matrix(df, features)
    y = Float64.(df[!, target])
    dates = df.date

    train, test = train_test_indices(nrow(df))

    results = DataFrame()
    predictions = DataFrame()

    # baseline
    baseline_metrics, baseline_predictions = evaluate_mean_baseline(
        location,
        target,
        dates[test],
        y[train],
        y[test]
    )

    append!(results, baseline_metrics)
    append!(predictions, baseline_predictions)

    models = [
        ("LinearRegression", LinearRegressor()),
        ("RidgeRegression", RidgeRegressor()),
        ("DecisionTree", DecisionTreeRegressor(max_depth=6)),
        ("RandomForest", RandomForestRegressor(n_trees=100))
    ]

    for (model_name, model) in models
        try
            metrics_df, predictions_df = evaluate_mlj_model(
                location,
                target,
                model_name,
                model,
                X,
                y,
                dates,
                train,
                test
            )

            append!(results, metrics_df)
            append!(predictions, predictions_df)
        catch e
            @warn "Model nie został uruchomiony" location model_name exception=e
        end
    end

    return results, predictions
end

# =========================
# Najlepsze modele
# =========================

function get_best_models(results::DataFrame)
    trained = filter(:model => !=("MeanBaseline"), results)

    best = combine(groupby(trained, [:location, :target])) do sdf
        sdf[argmin(sdf.rmse), :]
    end

    sort!(best, [:location])

    return best
end

function save_best_predictions(best_models::DataFrame, all_predictions::DataFrame)
    mkpath(PREDICTIONS_DIR)

    best_predictions_all = DataFrame()

    for row in eachrow(best_models)
        sub = filter(
            r -> r.location == row.location &&
                 r.target == row.target &&
                 r.model == row.model,
            all_predictions
        )

        sort!(sub, :date)

        file_name = "$(row.location)_best_predictions.csv"
        CSV.write(joinpath(PREDICTIONS_DIR, file_name), sub)

        append!(best_predictions_all, sub)
    end

    CSV.write(joinpath(PREDICTIONS_DIR, "best_predictions_all.csv"), best_predictions_all)

    return best_predictions_all
end

# =========================
# Wszystkie lokalizacje
# =========================

function run_all_models()
    mkpath(RESULTS_DIR)
    mkpath(PREDICTIONS_DIR)

    location_targets = [
        ("austin", :scent_daily),
        ("san_antonio", :scent_daily),
        ("dallas", :north_daily),
        ("houston", :coast_daily)
    ]

    all_results = DataFrame()
    all_predictions = DataFrame()

    for (location, target) in location_targets
        try
            location_results, location_predictions = run_models_for_location(location, target)
            append!(all_results, location_results)
            append!(all_predictions, location_predictions)
        catch e
            @warn "Pominięto lokalizację" location target exception=e
        end
    end

    if nrow(all_results) == 0
        error("Nie udało się uruchomić żadnego modelu. Sprawdź wcześniejsze warningi.")
    end

    sort!(all_results, [:location, :rmse])
    sort!(all_predictions, [:location, :model, :date])

    best_models = get_best_models(all_results)
    best_predictions_all = save_best_predictions(best_models, all_predictions)

    CSV.write(joinpath(RESULTS_DIR, "model_comparison.csv"), all_results)
    CSV.write(joinpath(RESULTS_DIR, "best_models.csv"), best_models)
    CSV.write(joinpath(PREDICTIONS_DIR, "all_predictions.csv"), all_predictions)
    CSV.write(joinpath(PREDICTIONS_DIR, "best_predictions_all.csv"), best_predictions_all)

    return all_results, best_models, all_predictions, best_predictions_all
end

results, best_models, all_predictions, best_predictions_all = run_all_models()

println()
println("Porównanie modeli:")
println(results)

println()
println("Najlepsze modele według RMSE:")
println(best_models)

println()
println("Predykcje najlepszych modeli zapisane w: $(PREDICTIONS_DIR)")