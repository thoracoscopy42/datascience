function loader(path::AbstractString)
    df = CSV.read(path, DataFrame)

    return df
end

function parse_numbers(cols)

    x = strip(String(cols))
    x = replace(x, " " => "")    
    x = replace(x, "," => ".")    

    return parse(Float64, x)
end