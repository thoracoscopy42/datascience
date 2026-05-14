
function loader(path::AbstractString)
    df = CSV.read(path, DataFrame)

    return df
end

function parse_ercot_date(x)

    # rekordy z czasem "24:00" były brane jako następny dzień, 
    # a powinny były jako ostatnia obserwacja z danego dnia
    # przez co pierwsza grupa miała 23 rekordy, a ostatnia 1 
    
    s = strip(String(x))

    if endswith(s, "24:00")
        return Date(first(s, 10), dateformat"mm/dd/yyyy")
    else
        return Date(DateTime(s, dateformat"mm/dd/yyyy HH:MM"))
    end
end

function parse_numbers(num)

    x = strip(String(num))
    x = replace(x, " " => "")    
    x = replace(x, "," => ".")    

    return parse(Float64, x)
end

#funkcje do agregate poniżej

function data_range(x)
    return maximum(x) - minimum(x)
end

function load_factor(x)
    return mean(x) / maximum(x)
end

function peak_ratio(x)
    return maximum(x) / mean(x)
end

function agregate_distribute(df::DataFrame; by_col=:date)

        agregated_df = combine(

            groupby(df, by_col),

            #SECTION - coast
            :coast => mean        => :coast_mean,
            :coast => sum         => :coast_daily,
            :coast => maximum     => :coast_max,
            :coast => minimum     => :coast_min,
            :coast => std         => :coast_std,
            :coast => data_range  => :coast_range,
            :coast => load_factor => :coast_load_factor,
            :coast => peak_ratio  => :coast_peak_ratio,


            #SECTION - north
            :north => mean        => :north_mean,
            :north => sum         => :north_daily,
            :north => maximum     => :north_max,
            :north => minimum     => :north_min,
            :north => std         => :north_std,
            :north => data_range  => :north_range,
            :north => load_factor => :north_load_factor,
            :north => peak_ratio  => :north_peak_ratio,
            
            #SECTION - scent
            :scent => mean        => :scent_mean,
            :scent => sum         => :scent_daily,
            :scent => maximum     => :scent_max,
            :scent => minimum     => :scent_min,
            :scent => std         => :scent_std,
            :scent => data_range  => :scent_range,
            :scent => load_factor => :scent_load_factor,
            :scent => peak_ratio  => :scent_peak_ratio,

            #SECTION - ercot
            :ercot => mean        => :ercot_mean,
            :ercot => sum         => :ercot_daily,
            :ercot => maximum     => :ercot_max,
            :ercot => minimum     => :ercot_min,
            :ercot => std         => :ercot_std,
            :ercot => data_range  => :ercot_range,
            :ercot => load_factor => :ercot_load_factor,
            :ercot => peak_ratio  => :ercot_peak_ratio
            )

        coast_tab = select(
            agregated_df,
            by_col,
            r"coast_"
        )

        north_tab = select(
            agregated_df,
            by_col,
            r"north_"
        )

        scent_tab = select(
            agregated_df,
            by_col,
            r"scent_"
        )

        ercot_tab = select(
            agregated_df,
            by_col,
            r"ercot_"
        )

        # CSV.write("data/partial/coast.csv", coast_tab)
        # CSV.write("data/partial/north.csv", north_tab)
        # CSV.write("data/partial/scent.csv", scent_tab)
        # CSV.write("data/partial/ercot.csv", ercot_tab)
        
        # CSV.write("data/processed/energy.csv", agregated_df)


    return agregated_df 
end

