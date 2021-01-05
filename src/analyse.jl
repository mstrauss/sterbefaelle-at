using DataFrames
using Dates
using Interpolations
using Plots
using Plots.PlotMeasures
using Statistics

function analyse(df_unstacked,
                 filename="deceased_at",
                 lang=:en,
                 location="Austria",
                 analysis_year=2020)

    df = aggregate(coalesce.(df_unstacked[[:week, :below65, :above65]], 0), :week, sum)

    df.year = (x->parse(Int,x[6:9])).(df.week)
    df.week = (x->parse(Int,x[10:11])).(df.week)

    # date of first monday of first year in the DF
    first_year = df.year[1]
    first_monday = Dates.tofirst(Dates.Date(first_year, 1, 1), 1, of=Year)

    df.first_day_of_week = first_monday .+ Dates.Day.([0:nrow(df)-1...].*7)

    df_obs = df[first_year .<= df.year .<= analysis_year, :]
    df_obs = df_obs[:, [5,2,3]]

    # we want to use the last day of the week instead of first
    df_obs.last_day_of_week = df_obs.first_day_of_week .+ Dates.Day(6)

    # df_obs = df_obs[:, [:last_day_of_week, :below65_sum, :above65_sum]]
    rename!(df_obs, :below65_sum => :below65, :above65_sum => :above65)

    # applying linear interpolation, s.t. at the end of the reporting
    # week the interpolated death count equals the reported death
    # count
    df_obs.day = Dates.date2epochdays.(df_obs.last_day_of_week)
    day_range = LinRange(first(df_obs.day), last(df_obs.day), nrow(df))
    fun = BSpline(Linear())
    above65 = scale(
        extrapolate(interpolate(Float64.(df_obs.above65), fun), Line()),
        day_range)
    below65 = scale(
        extrapolate(interpolate(Float64.(df_obs.below65), fun), Line()),
        day_range)

    # generate new dataset where we have an approximate daily
    # resolution OF THE WEEKLY NUMBERS based on the interpolation
    t = Dates.date2epochdays(Date(first_year, 1, 1)) : last(df_obs.day)
    df_int = DataFrame(
        :day => Dates.epochdays2date.(t),
        :below65 => below65(t),
        :above65 => above65(t))

    # add 'group' (for aggregation)
    df_int.group = Dates.format.(df_int.day, Dates.DateFormat("mm-dd"))

    # remove Feb 29
    filter!(row -> row.group != "02-29", df_int)

    # interpolated dataset, selected years for comparison
    df_int_cmp_sel = df_int[
        (df_int.day .>= Date(analysis_year-10,1,1)) .&
        (df_int.day .<= Date(analysis_year-1,12,31)), :]

    df_cmp_sel = aggregate(df_int_cmp_sel[[:group, :below65, :above65]], :group, [mean, std])

    # # re-insert day
    # df_cmp_sel.day = Date.(string.(analysis_year, "-", df_cmp_sel.group))

    # # drop 'group'
    # select!(df_cmp_sel, Not(:group))
    # select!(df_int, Not(:group))

    start_date = first(df_int.day)

    # xticks = start_week:3:end_week
    # xticks = (xticks, map(x->@sprintf("%s", x < 0 ? x+52 : x), xticks))

    if lang == :de
        xlabel = "Tag"
        lab1 = "$(analysis_year-10)-$(analysis_year-1) Mittelw. / punktw. 95% Konf.int."
        lab2 = "$(analysis_year)"
        lab3 = ""
        lab4 = "über 65-Jährige"
        lab5 = "0 bis 64-Jährige"
        lab6 = "Sterbefälle in $(location) $(analysis_year)"
        lab7 = "nach Kalenderwochen"
        lab8 = "Datenquelle: Statistik Austria - data.statistik.gv.at\nAnalyse: Markus Strauss - https://github.com/mstrauss/sterbefaelle-at"
    else
        xlabel = "day"
        lab1 = "$(analysis_year-10)-$(analysis_year-1) mean / pointw. 95% conf. int."
        lab2 = "$(analysis_year)"
        lab3 = ""
        lab4 = "age ≥ 65"
        lab5 = "age < 65"
        lab6 = "Deceased in $(location), $(analysis_year)"
        lab7 = "(absolute weekly numbers by age group)"
        lab8 = "Data source: Statistik Austria - data.statistik.gv.at\nAnalysis: Markus Strauss - https://github.com/mstrauss/sterbefaelle-at"
    end

    if maximum(df_cmp_sel.above65_mean) > 380
        ymax = 2500
        lab4y = 2300
        lab5y = 450
        lab6y = 3600
        lab7y = 3350
        lab8y = -750
    else
        ymax = 440
        lab4y = 420
        lab5y = 110
        lab6y = 620
        lab7y = 580
        lab8y = -120
    end

    # the averages from previous years
    plot()
    plot(legend=:outertop,
         legendfont=6,
         xlabel=xlabel,
         guidefont=10,
         # xticks=xticks,
         xtickfont = 10,
         ylims=[0, ymax],
         ytickfont = font("Arial", 10, :lightgray),
         grid=:y,
         size=(400,380),
         top_margin=13mm,
         bottom_margin=4mm,
         # title=lab6,
         subtitle=lab7,
         )

    df_sel = df_int[
        (df_int.day .>= Date(analysis_year,1,1)) .&
        (df_int.day .<= Date(analysis_year,12,31)), :]

    # joining the means and standard deviations
    df_sel = leftjoin(df_cmp_sel, df_sel, on = :group)

    # default formats
    label = :none
    alpha = 0.4
    color = :gray
    linewidth = 1

    # specific formats
    if true # year == analysis_year
        color = colorant"#e66101"
        linewidth = 3
        alpha = 1.0
        label = lab2

        # plot ribbons
        plot!(df_sel.below65_mean,
              ribbon=df_cmp_sel.below65_std*2,
              label=lab1,
              color=:gray, linestyle=:dash)
        plot!(df_sel.above65_mean,
              ribbon=df_sel.above65_std*2,
              label=:none,
              color=:gray, linestyle=:dash)
    end
    # elseif year == 2017
    #     color = colorant"#fdb863"
    #     linewidth = 1.75
    #     alpha = 0.5
    #     label = "2016/17"  # Influenza H3N2?
    # elseif year == 2018
    #     color = colorant"#5e3c99"
    #     label = "2017/18"
    #     linewidth = 1.75
    #     alpha= 0.5
    # end
    #
    # if year == 2016
    #     label = lab3
    # end

    # the current series
    plot!(df_sel.below65, label=label,
          linewidth=linewidth, color=color, alpha=alpha)
    plot!(df_sel.above65, label=:none,
          linewidth=linewidth, color=color, alpha=alpha)

    # annotations
    plot!(annotate=(1, lab4y, text(lab4, :left, 10)))
    plot!(annotate=(1, lab5y, text(lab5, :left, 10)))

    plot!(annotate=(1, lab6y, text(lab6, :left, 12)))
    plot!(annotate=(1, lab7y, text(lab7, :left, 10)))

    # original: https://apa.liveblog.pro/apa/20200420120448/4ab3006a5ed1d98669d816405f5eb2e4e7c51c0c75eb4dd5786ae31b9edf1a6b.jpg
    plot!(annotate=(1, lab8y, text(lab8, :left, 4)))

    # export
    pdfname = string(filename, ".pdf")
    pngname = string(filename, ".png")
    savefig(pdfname)

    Base.run(`convert -density 120 $pdfname $pngname`)
end
