# README

Data source: [Statistik Austria, "Gestorbene in Österreich (ohne Auslandssterbefälle) ab 2000 nach Kalenderwoche"](https://data.statistik.gv.at/web/meta.jsp?dataset=OGD_gest_kalwo_GEST_KALWOCHE_100).

License of the Julia source code: see LICENSE.


## Requirements

- GNU/Linux
- Julia 1.4.x
- ImageMagick 7
- Ruby 2.6.6


## Setup

- Install the requirements, including Julia.
- Clone the repository.
- Run `julia --project=.` from the repo base directory.
- From within Julia execute `Pkg.status()` to show required Julia packages and `Pkg.instantiate()` to install them.  Exit Julia.
- Run `rake` 



## Troubleshooting

- ImageMagick error `convert: attempt to perform an operation not allowed by the security policy`:

	Remove the line `<policy domain="delegate" rights="none" pattern="gs" />` in `/etc/ImageMagick-7/policy.xml`.
