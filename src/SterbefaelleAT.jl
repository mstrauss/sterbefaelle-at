module SterbefaelleAT

include("remote_data.jl")
include("settings.jl")
include("analyse.jl")

function wien()
    df_unstacked = remote_data()
    @printf("Only keeping data from Vienna.\n")
    df_unstacked = df_unstacked[df_unstacked.province.=="B00-9", :]
    analyse(df_unstacked, "sterbefaelle_wien", :de)
end

function at_de()
    df_unstacked = remote_data()
    analyse(df_unstacked, "sterbefaelle_at", :de)
end

function at_en()
    df_unstacked = remote_data()
    analyse(df_unstacked, "deceased_at", :en)
end

function run()
    wien()
    at_de()
    at_en()
end

end # module
