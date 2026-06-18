using CSV
using DataFrames
using CairoMakie

const RESULTS_PATH = joinpath("data", "processed", "modeling", "model_comparison.csv")
const OUT_DIR = joinpath("plots", "generated")

mkpath(OUT_DIR)

function pretty_location_name(location::AbstractString)
    location_str = String(location)
    return titlecase(replace(location_str, "_" => " "))
end

function pretty_model_name(model::AbstractString)
    mapping = Dict(
        "LinearRegression" => "Linear",
        "RidgeRegression" => "Ridge",
        "DecisionTree" => "Decision Tree",
        "RandomForest" => "Random Forest",
        "MeanBaseline" => "Mean Baseline"
    )
    return get(mapping, model, model)
end

function ordered_subset(df::DataFrame, order::Vector{String})
    parts = DataFrame[]
    for name in order
        sub = filter(:model => ==(name), df)
        if nrow(sub) > 0
            push!(parts, sub)
        end
    end

    if isempty(parts)
        return DataFrame()
    end

    return vcat(parts...)
end

function metric_label(x::Real)
    if abs(x) >= 10000
        return string(round(x, digits=0))
    elseif abs(x) >= 1000
        return string(round(x, digits=1))
    elseif abs(x) >= 100
        return string(round(x, digits=2))
    else
        return string(round(x, digits=3))
    end
end

function add_value_labels!(ax, xs, ys; offset_fraction=0.03)
    ymin, ymax = minimum(ys), maximum(ys)
    span = ymax - ymin
    offset = span == 0 ? 0.05 : span * offset_fraction

    for (x, y) in zip(xs, ys)
        text!(
            ax,
            x,
            y + offset,
            text = metric_label(y),
            align = (:center, :bottom),
            fontsize = 12
        )
    end
end

function build_summary_text(location_df::DataFrame)
    trained = filter(:model => !=("MeanBaseline"), location_df)
    baseline = filter(:model => ==("MeanBaseline"), location_df)

    best_idx = argmin(trained.rmse)
    best = trained[best_idx, :]

    baseline_rmse = baseline.rmse[1]
    baseline_mae = baseline.mae[1]

    rmse_improvement = 100 * (baseline_rmse - best.rmse) / baseline_rmse
    mae_improvement = 100 * (baseline_mae - best.mae) / baseline_mae

    return """
Best model (by RMSE): $(pretty_model_name(best.model))
RMSE: $(metric_label(best.rmse))   |   MAE: $(metric_label(best.mae))   |   R²: $(round(best.r2, digits=6))

Baseline RMSE: $(metric_label(baseline_rmse))
Baseline MAE:  $(metric_label(baseline_mae))

Improvement vs baseline:
RMSE: $(round(rmse_improvement, digits=2))%
MAE:  $(round(mae_improvement, digits=2))%
"""
end

function plot_region_results(results::DataFrame, location::String)
    region_df = filter(:location => ==(location), results)

    if nrow(region_df) == 0
        @warn "Brak danych dla lokalizacji" location
        return nothing
    end

    full_order = [
        "RidgeRegression",
        "LinearRegression",
        "DecisionTree",
        "RandomForest",
        "MeanBaseline"
    ]

    trained_order = [
        "RidgeRegression",
        "LinearRegression",
        "DecisionTree",
        "RandomForest"
    ]

    region_df = ordered_subset(region_df, full_order)
    trained_df = ordered_subset(filter(:model => !=("MeanBaseline"), region_df), trained_order)

    trained_labels = [pretty_model_name(m) for m in trained_df.model]
    all_labels = [pretty_model_name(m) for m in region_df.model]

    x_trained = 1:nrow(trained_df)
    x_all = 1:nrow(region_df)

    fig = Figure(size = (1500, 1050))

    Label(
        fig[0, 1:2],
        "Model comparison for $(pretty_location_name(location))",
        fontsize = 28,
        font = :bold
    )

    # MAE
    ax1 = Axis(
        fig[1, 1],
        title = "MAE (trained models only)",
        xlabel = "Model",
        ylabel = "MAE"
    )
    barplot!(ax1, x_trained, trained_df.mae)
    ax1.xticks = (x_trained, trained_labels)
    ax1.xticklabelrotation = pi / 8
    add_value_labels!(ax1, x_trained, trained_df.mae)

    # RMSE
    ax2 = Axis(
        fig[1, 2],
        title = "RMSE (trained models only)",
        xlabel = "Model",
        ylabel = "RMSE"
    )
    barplot!(ax2, x_trained, trained_df.rmse)
    ax2.xticks = (x_trained, trained_labels)
    ax2.xticklabelrotation = pi / 8
    add_value_labels!(ax2, x_trained, trained_df.rmse)

    # R²
    ax3 = Axis(
        fig[2, 1:2],
        title = "R² (all models)",
        xlabel = "Model",
        ylabel = "R²"
    )
    barplot!(ax3, x_all, region_df.r2)
    ax3.xticks = (x_all, all_labels)
    ax3.xticklabelrotation = pi / 8
    add_value_labels!(ax3, x_all, region_df.r2; offset_fraction=0.01)

    # Summary text
    summary_text = build_summary_text(region_df)

    Label(
        fig[3, 1:2],
        summary_text,
        fontsize = 16,
        justification = :left,
        halign = :left,
        valign = :top,
        tellwidth = false
    )

    base_name = lowercase(replace(location, " " => "_"))
    save(joinpath(OUT_DIR, "$(base_name)_model_comparison.png"), fig)
    save(joinpath(OUT_DIR, "$(base_name)_model_comparison.svg"), fig)

    return fig
end

function plot_best_models_summary(results::DataFrame)
    trained = filter(:model => !=("MeanBaseline"), results)

    best_rows = DataFrame()

    for loc in unique(trained.location)
        sub = filter(:location => ==(loc), trained)
        best = sub[argmin(sub.rmse), :]
        push!(best_rows, best)
    end

    sort!(best_rows, :rmse)

    labels = [pretty_location_name(loc) * "\n(" * pretty_model_name(model) * ")" for (loc, model) in zip(best_rows.location, best_rows.model)]
    x = 1:nrow(best_rows)

    fig = Figure(size = (1200, 700))
    ax = Axis(
        fig[1, 1],
        title = "Best model in each region (by RMSE)",
        xlabel = "Region",
        ylabel = "RMSE"
    )

    barplot!(ax, x, best_rows.rmse)
    ax.xticks = (x, labels)
    add_value_labels!(ax, x, best_rows.rmse)

    save(joinpath(OUT_DIR, "best_models_summary.png"), fig)
    save(joinpath(OUT_DIR, "best_models_summary.svg"), fig)

    return fig
end

function main()
    if !isfile(RESULTS_PATH)
        error("Brak pliku wynikowego: $(RESULTS_PATH)")
    end

    results = CSV.read(RESULTS_PATH, DataFrame)

    locations = ["austin", "dallas", "houston", "san_antonio"]

    for loc in locations
        plot_region_results(results, loc)
    end

    plot_best_models_summary(results)

    println("Wykresy zapisane do folderu: $(OUT_DIR)")
end

main()