# STATISTICS OF HARRY POTTER FAN FICTIONS #
*Project for subject OPB (Osnove podatkovnih baz), Faculty of Mathematics and Physics, University of Ljubljana, year 2015/2016.*

The data will be acquired from [Archive of Our Own](https://archiveofourown.org/).

Python 3.4 and library [`requests`](http://docs.python-requests.org/en/master/) will be used to acquire the data, while parsing will be handled with the library [`BeautifulSoup`](http://www.crummy.com/software/BeautifulSoup/). The data will then be stored in a PostgreSQL database, available at [baza.fmf.uni-lj.si](http://baza.fmf.uni-lj.si/), which will be created and filled using Python and library [`psycopg2`](https://pypi.python.org/pypi/psycopg2). 

## Requirements ##

In order for the shiny application to work correctly, the following R packages must be installed:

* `shiny`
* `dplyr`
* `RPostgreSQL`
* `ggplot2`
* `gridExtra`

Furthermore, the developer version of the package `DT` must be installed, which can be achieved by running the following code snippet in RStudio:
```r
install.packages("devtools")
devtools::install_github('rstudio/DT')
```
Further information on this package can be found on [this](https://github.com/rstudio/DT) GitHub repository.

Last but not least, an `auth_public.R` file must be included in the `shiny_application` folder, in order to gain access to the database. This file should contain:

```r
db = 'sem2016_inesm'
host = 'baza.fmf.uni-lj.si'
user = 'javnost'
password = 'javnogeslo'
```

## Entity-relationship diagram of the database ##

![ER diagram](https://bytebucket.org/Emayla/fan-fiction-stats/raw/ae63f0504f31e1ee663934468236d9015aa4d560/er_diagram/ERdiagram.png "ER diagram")

The diagram was created with [Dia](http://dia-installer.de/).


### Authors ###
Matic Oskar Hajšen, Ines Meršak