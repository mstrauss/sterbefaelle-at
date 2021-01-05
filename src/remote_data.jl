ENV["GKS_ENCODING"]="utf-8"

using CSV
using DataFrames
using Plots
using Plots.PlotMeasures
using Printf
using Statistics

function remote_data()

    csv_dirname = "data"
    csv_filename = "OGD_gest_kalwo_GEST_KALWOCHE_100.csv"
    local_filename = joinpath(csv_dirname, csv_filename)
    if !isfile(local_filename)
        url = "https://data.statistik.gv.at/data/OGD_gest_kalwo_GEST_KALWOCHE_100.csv"
        @printf("Downloading and saving data from %s...", url)
        tmpfile = download(url)
        isdir(csv_dirname) || mkdir(csv_dirname)
        mv(tmpfile, local_filename)
    end

    @printf("Reading %s.\n", local_filename)
    df_raw = CSV.read(local_filename, DataFrame)

    df_unstacked = unstack(df_raw,
                           [
                               # unique row key columns
                               Symbol("C-KALWOCHE-0"),
                               Symbol("C-B00-0"),
                               Symbol("C-C11-0"),
                           ],
                           Symbol("C-ALTERGR65-0"),
                           Symbol("F-ANZ-1"))
    rename!(df_unstacked, [:week, :province, :sex, :below65, :above65])

    return df_unstacked
end
