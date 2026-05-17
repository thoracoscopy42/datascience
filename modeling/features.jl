using DataFrames
using Dates
using ScientificTypes

function add_calendar_features!(df::DataFrame)

    df.month = Float64.(month.(df.date))
    df.dayofweek = Float64.(dayofweek.(df.date))
    df.is_weekend = Float64.(in.(dayofweek.(df.date), Ref([6, 7])))

    return df
end

function prepare_model_frame!(
    df::DataFrame;
    target::Symbol,
    features::Vector{Symbol}
)

    selected_columns = vcat([:date], features, [target])    

    select!(df, selected_columns)
    dropmissing!(df)
    sort!(df, :date)

    coerce!(
        df,
        Count => Continuous,
        target => Continuous
    )
    return df
end

function split_xy(df::DataFrame; target::Symbol)
    X = select(df, Not([:date, target]))
    y = df[!, target]

    return X, y
end

function split_data_for_regression(X, y; train_ratio=0.8)

    @assert 0 < train_ratio < 1 
    @assert nrow(X) == length(y)

    n = nrow(X)
    train_end = floor(Int, train_ratio * n)

    @assert train_end > 0 
    @assert train_end < n

    train_idx = 1:train_end
    test_idx = (train_end + 1):n

    return (
            X_train = X[train_idx, :],
            y_train = y[train_idx],
            X_test  = X[test_idx, :],
            y_test  = y[test_idx],
    )
end