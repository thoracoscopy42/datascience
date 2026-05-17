using Statistics

function mae(y_true, y_pred)
    return mean(abs.(y_true .- y_pred))   
end

function rmse(y_true, y_pred)
    return sqrt(mean((y_true .- y_pred) .^ 2))
end

function mape(y_true, y_pred)
    valid_idx = y_true .!=0

    if sum(valid_idx) == 0
        return missing
    end

    return mean(abs.((y_true[valid_idx] .- y_pred[valid_idx]) ./ y_true[valid_idx])) * 100
end

function r2_score(y_true, y_pred)

    res = sum((y_true .- y_pred) .^ 2)
    tot = sum((y_true .- mean(y_true)) .^ 2)

    return 1 - ( res / tot)
end

function regression_report(y_true, y_pred)

    return (
        MAE  = mae(y_true, y_pred),
        RMSE = rmse(y_true, y_pred),
        MAPE = mape(y_true, y_pred),
        R2   = r2_score(y_true, y_pred)
    )
    
end