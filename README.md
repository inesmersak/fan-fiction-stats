# STATISTICS OF HARRY POTTER FAN FICTIONS #
*Project for subject OPB (Osnove podatkovnih baz), Faculty of Mathematics and Physics, University of Ljubljana, year 2015/2016.*

The data will be acquired at [Archive of Our Own](https://archiveofourown.org/).

Python 3.4 and library [`requests`](http://docs.python-requests.org/en/master/) will be used to acquire the data, while parsing will be handled with the library [`BeautifulSoup`](http://www.crummy.com/software/BeautifulSoup/). The data will then be stored in a PostgreSQL database, available at [baza.fmf.uni-lj.si](http://baza.fmf.uni-lj.si/), which will be created and filled using Python and library [`psycopg2`](https://pypi.python.org/pypi/psycopg2). 

## Entity-relationship diagram of the database ##

![ER diagram](https://bytebucket.org/Emayla/fan-fiction-stats/raw/ae63f0504f31e1ee663934468236d9015aa4d560/er_diagram/ERdiagram.png "ER diagram")

The diagram was created with [Dia](http://dia-installer.de/).

## Requirements ##

In order for the shiny application to work correctly, the developer version of the package `DT` must be installed using the instructions on [this](https://github.com/rstudio/DT) GitHub repository.

### Authors ###
Matic Oskar Hajšen, Ines Meršak