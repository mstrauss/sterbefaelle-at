# rule ".png" => ".jl" do |t|
#   sh "julia #{t.source}"
# end

# task :default => [
#        "sterbefaelle_at.png",
#        "sterbefaelle_wien.png",
#        "deceased_at.png",
#      ]

desc "remove data (will be fetched by 'run')"
task :clean_data do
  rm_rf "data/OGD_gest_kalwo_GEST_KALWOCHE_100.csv"
end

desc "generate all graphics"
task :run do
  sh "julia --project=. all.jl"
end

task :default => [:clean_data, :run]
