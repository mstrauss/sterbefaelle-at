function analyse(df_unstacked,
                 filename="deceased_at",
                 lang=:en,
                 location="Austria")

    df = aggregate(coalesce.(df_unstacked[[:week, :below65, :above65]], 0), :week, sum)

    df.year = (x->parse(Int,x[6:9])).(df.week)
    df.week = (x->parse(Int,x[10:11])).(df.week)

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

    if lang == :de
        xlabel = "Kalenderwoche"
        lab1 = "2008/09–2018/19 Mittelw. / punktw. 95% Konf.int."
        lab2 = "2019/20 (vorläufige Daten)"
        lab3 = "2008/09–2018/19 (nicht: 16/17, 17/18)"
        lab4 = "über 65-Jährige"
        lab5 = "0 bis 64-Jährige"
        lab6 = "Sterbefälle in $(location) 2019/2020"
        lab7 = "nach Kalenderwochen"
        lab8 = "Datenquelle: Statistik Austria - data.statistik.gv.at\nAnalyse: Markus Strauss - https://github.com/mstrauss/sterbefaelle-at"
    else
        xlabel = "week"
        lab1 = "2008/09–2018/19 mean / pointw. 95% conf. int."
        lab2 = "2019/20 (prelim. data)"
        lab3 = "2008/09–2018/19 (excl. 16/17, 17/18)"
        lab4 = "age ≥ 65"
        lab5 = "age < 65"
        lab6 = "Deceased in $(location), 2019/2020"
        lab7 = "(absolute weekly numbers by age group)"
        lab8 = "Data source: Statistik Austria - data.statistik.gv.at\nAnalysis: Markus Strauss - https://github.com/mstrauss/sterbefaelle-at"
    end

    if maximum(df_cmp_sel.above65_mean) > 380
        ymax = 2500
        lab4y = 2300
        lab5y = 450
        lab6y = 4200
        lab7y = 3950
        lab8y = -750
    else
        ymax = 440
        lab4y = 420
        lab5y = 110
        lab6y = 750
        lab7y = 700
        lab8y = -120
    end

    # the averages from previous years
    plot()
    plot(legend=:outertop,
         legendfont=6,
         xlabel=xlabel,
         guidefont=10,
         xticks=xticks,
         xtickfont = 10,
         ylims=[0, ymax],
         ytickfont = font("Arial", 10, :lightgray),
         grid=:y,
         size=(400,380),
         top_margin=13mm,
         bottom_margin=4mm,
         )

    plot!(df_cmp_sel.week, df_cmp_sel.below65_mean,
          ribbon=df_cmp_sel.below65_std*2,
          label=lab1,
          color=:gray, linestyle=:dash)
    plot!(df_cmp_sel.week, df_cmp_sel.above65_mean,
          ribbon=df_cmp_sel.above65_std*2,
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
            label = lab2
        elseif year == 2017
            color = colorant"#fdb863"
            linewidth = 1.75
            alpha = 0.5
            label = "2016/17"  # Influenza H3N2?
        elseif year == 2018
            color = colorant"#5e3c99"
            label = "2017/18"
            linewidth = 1.75
            alpha= 0.5
        end

        if year == 2016
            label = lab3
        end

        # the current series
        plot!(df_sel.week, df_sel.below65_sum, label=label,
              linewidth=linewidth, color=color, alpha=alpha)
        plot!(df_sel.week, df_sel.above65_sum, label=:none,
              linewidth=linewidth, color=color, alpha=alpha)
    end

    # annotations
    plot!(annotate=(start_week, lab4y, text(lab4, :left, 10)))
    plot!(annotate=(start_week, lab5y, text(lab5, :left, 10)))

    plot!(annotate=(start_week-3, lab6y, text(lab6, :left, 12)))
    plot!(annotate=(start_week-3, lab7y, text(lab7, :left, 10)))

    # original: https://apa.liveblog.pro/apa/20200420120448/4ab3006a5ed1d98669d816405f5eb2e4e7c51c0c75eb4dd5786ae31b9edf1a6b.jpg
    plot!(annotate=(start_week-3, lab8y, text(lab8, :left, 4)))

    # export
    pdfname = string(filename, ".pdf")
    pngname = string(filename, ".png")
    savefig(pdfname)

    Base.run(`convert -density 120 $pdfname $pngname`)
end
