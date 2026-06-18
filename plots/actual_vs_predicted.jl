using CSV
using DataFrames
using CairoMakie
using Statistics

const BEST_MODELS_PATH = joinpath("data", "processed", "modeling", "best_models.csv")
const BEST_PRED_PATH = joinpath("data", "processed", "modeling", "predictions", "best_predictions_all.csv")
const OUT_DIR = joinpath("plots", "generated", "actual_vs_predicted")

mkpath(OUT_DIR)

function pretty_location_name(location::String)
    return titlecase(replace(location, "_" => " "))
end

function pretty_model_name(model::String)
    mapping = Dict(
        "LinearRegression" => "Linear Regression",
        "RidgeRegression" => "Ridge Regression",
        "DecisionTree" => "Decision Tree",
        "RandomForest" => "Random Forest",
        "MeanBaseline" => "Mean Baseline"
    )
    return get(mapping, model, model)
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

function compute_metrics(df::DataFrame)
    y = Float64.(df.actual)
    ŷ = Float64.(df.predicted)

    mae = mean(abs.(y .- ŷ))
    rmse = sqrt(mean((y .- ŷ).^2))
    ss_res = sum((y .- ŷ).^2)
    ss_tot = sum((y .- mean(y)).^2)
    r2 = 1 - ss_res / ss_tot

    return mae, rmse, r2
end

function plot_region_actual_vs_predicted(best_models::DataFrame, preds::DataFrame, location::String)
    sub = filter(:location => ==(location), preds)

    if nrow(sub) == 0
        @warn "Brak predykcji dla lokalizacji" location
        return nothing
    end

    sort!(sub, :date)

    best_model_row = filter(:location => ==(location), best_models)
    if nrow(best_model_row) == 0
        @warn "Brak wiersza best_model dla lokalizacji" location
        return nothing
    end

    model_name = best_model_row.model[1]
    target_name = best_model_row.target[1]

    mae, rmse, r2 = compute_metrics(sub)

    y_min = min(minimum(sub.actual), minimum(sub.predicted))
    y_max = max(maximum(sub.actual), maximum(sub.predicted))

    obs = 1:nrow(sub)

    fig = Figure(size = (1600, 900))

    Label(
        fig[0, 1:2],
        "Actual vs Predicted — $(pretty_location_name(location))",
        fontsize = 28,
        font = :bold
    )

    # Lewy panel: przebieg actual/predicted
    ax1 = Axis(
        fig[1, 1],
        title = "Test observations (sorted by date)",
        xlabel = "Observation index",
        ylabel = String(target_name)
    )

    lines!(ax1, obs, sub.actual, label = "Actual")
    lines!(ax1, obs, sub.predicted, label = "Predicted")

    axislegend(ax1, position = :rb)

    # Prawy panel: scatter actual vs predicted
    ax2 = Axis(
        fig[1, 2],
        title = "Scatter: actual vs predicted",
        xlabel = "Actual",
        ylabel = "Predicted"
    )

    scatter!(ax2, sub.actual, sub.predicted)
    lines!(ax2, [y_min, y_max], [y_min, y_max], label = "Ideal fit: y = x")

    axislegend(ax2, position = :rb)

    summary_text = """
Best model: $(pretty_model_name(model_name))

MAE:  $(metric_label(mae))
RMSE: $(metric_label(rmse))
R²:   $(round(r2, digits=6))

Test observations: $(nrow(sub))
Date range:
$(minimum(sub.date)) → $(maximum(sub.date))
"""

    Label(
        fig[2, 1:2],
        summary_text,
        fontsize = 16,
        justification = :left,
        halign = :left,
        valign = :top,
        tellwidth = false
    )

    save(joinpath(OUT_DIR, "$(location)_actual_vs_predicted.png"), fig)
    save(joinpath(OUT_DIR, "$(location)_actual_vs_predicted.svg"), fig)

    return fig
end

function plot_combined_scatter(best_models::DataFrame, preds::DataFrame)
    fig = Figure(size = (1400, 1000))
    Label(fig[0, 1:2], "Actual vs Predicted — All regions", fontsize = 28, font = :bold)

    locations = ["austin", "dallas", "houston", "san_antonio"]

    for (i, loc) in enumerate(locations)
        sub = filter(:location => ==(loc), preds)
        best_model_row = filter(:location => ==(loc), best_models)

        if nrow(sub) == 0 || nrow(best_model_row) == 0
            continue
        end

        row = ceil(Int, i / 2)
        col = isodd(i) ? 1 : 2

        ax = Axis(
            fig[row, col],
            title = "$(pretty_location_name(loc)) — $(pretty_model_name(best_model_row.model[1]))",
            xlabel = "Actual",
            ylabel = "Predicted"
        )

        scatter!(ax, sub.actual, sub.predicted)

        y_min = min(minimum(sub.actual), minimum(sub.predicted))
        y_max = max(maximum(sub.actual), maximum(sub.predicted))
        lines!(ax, [y_min, y_max], [y_min, y_max])
    end

    save(joinpath(OUT_DIR, "all_regions_actual_vs_predicted.png"), fig)
    save(joinpath(OUT_DIR, "all_regions_actual_vs_predicted.svg"), fig)

    return fig
end

function main()
    if !isfile(BEST_MODELS_PATH)
        error("Brak pliku: $(BEST_MODELS_PATH)")
    end

    if !isfile(BEST_PRED_PATH)
        error("Brak pliku: $(BEST_PRED_PATH)")
    end

    best_models = CSV.read(BEST_MODELS_PATH, DataFrame)
    preds = CSV.read(BEST_PRED_PATH, DataFrame)

    locations = ["austin", "dallas", "houston", "san_antonio"]

    for loc in locations
        plot_region_actual_vs_predicted(best_models, preds, loc)
    end

    plot_combined_scatter(best_models, preds)

    println("Wykresy actual vs predicted zapisane do: $(OUT_DIR)")
end

main()