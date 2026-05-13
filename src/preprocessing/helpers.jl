function loader(path::AbstractString)
    df = CSV.read(path, DataFrame)

    return df
end

function parse_numbers(num)

    x = strip(String(num))
    x = replace(x, " " => "")    
    x = replace(x, "," => ".")    

    return parse(Float64, x)
end
