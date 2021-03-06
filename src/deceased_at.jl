ENV["GKS_ENCODING"]="utf-8"

using CSV
using DataFrames
using Plots
using Plots.PlotMeasures
using Printf
using Statistics

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
df_raw = CSV.read(local_filename)

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

df = aggregate(coalesce.(df_unstacked[[:week, :below65, :above65]], 0), :week, sum)

df.year = (x->parse(Int,x[6:9])).(df.week)
df.week = (x->parse(Int,x[10:11])).(df.week)

include("settings.jl")

for year in unique(df.year)[1:end-1]
    sel = (df.year .== year) .& (df.week .> end_week)
    no_weeks_this_year = maximum(df.week[df.year.==year])
    df.week[sel] = df.week[sel].-no_weeks_this_year
    df.year[sel] = df.year[sel].+1
end

df_obs = df[2009 .<= df.year .<= 2019, :]
rename!(df_obs, [:week, :below65, :above65, :year])

df_cmp = aggregate(df_obs[[:week, :below65, :above65]], :week, [mean, std])
df_cmp_sel = df_cmp[start_week .<= df_cmp.week .<= end_week, :]

xticks = start_week:3:end_week
xticks = (xticks, map(x->@sprintf("%s", x < 0 ? x+52 : x), xticks))

# the averages from previous years
plot()
plot(legend=:outertop,
     legendfont=10,
     xlabel="week",
     guidefont=10,
     xticks=xticks,
     xtickfont = 10,
     ylims=[0, 2200],
     ytickfont = font("Arial", 10, :lightgray),
     grid=:y,
     size=(400,380),
     top_margin=13mm,
     bottom_margin=4mm,
)

plot!(df_cmp_sel.week, df_cmp_sel.below65_mean,
      ribbon=df_cmp_sel.below65_std,
      label="2008/09–2018/19 mean/std.dev.",
      color=:gray, linestyle=:dash)
plot!(df_cmp_sel.week, df_cmp_sel.above65_mean,
      ribbon=df_cmp_sel.above65_std,
      label=:none,
      color=:gray, linestyle=:dash)
    
for year in 2009:2020
    df_sel = df[(df.year .== year) .& (start_week .<= df.week .<= end_week), :]

    # default formats
    label = :none
    alpha = 0.4
    color = :gray
    linewidth = 1

    # specific formats
    if year == 2020
        color = colorant"#e66101"
        linewidth = 3
        alpha = 1.0
        label = "2019/20 (prelim. data)"
    elseif year == 2017
        color = colorant"#fdb863"
        linewidth = 1.75
        alpha = 0.5
        label = "2016/17"
    elseif year == 2018
        color = colorant"#5e3c99"
        label = "2017/18"
        linewidth = 1.75
        alpha= 0.5
    end

    if year == 2016
        label = "2008/09–2018/19 (excl. 16/17, 17/18)"
    end
    
    # the current series
    plot!(df_sel.week, df_sel.below65_sum, label=label,
          linewidth=linewidth, color=color, alpha=alpha)
    plot!(df_sel.week, df_sel.above65_sum, label=:none,
          linewidth=linewidth, color=color, alpha=alpha)
end

# annotations
plot!(annotate=(start_week, 1600, text("age ≥ 65", :left, 10)))
plot!(annotate=(start_week, 450, text("age < 65", :left, 10)))

plot!(annotate=(start_week-3, 4550, text("Deceased in Austria, 2019/2020", :left, 12)))
plot!(annotate=(start_week-3, 4300, text("(absolute weekly numbers by age group)", :left, 10)))
plot!(annotate=(start_week-3, -750, text("Data source: Statistik Austria - data.statistik.gv.at\nAnalysis: Markus Strauss - https://github.com/mstrauss/sterbefaelle-at", :left, 4)))

# export
savefig("deceased_at.pdf")

run(`convert -density 120 deceased_at.pdf deceased_at.png`)
