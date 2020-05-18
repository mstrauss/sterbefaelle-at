rule ".png" => ".jl" do |t|
  sh "julia #{t.source}"
end

task :default => [
       "sterbefaelle_at.png",
       "sterbefaelle_wien.png",
       "deceased_at.png",
     ]
