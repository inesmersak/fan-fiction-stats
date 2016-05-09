library(shiny)
library(dplyr)
library(RPostgreSQL)

source("auth.R")

shinyServer(function(input, output) {
  # Vzpostavimo povezavo
  conn <- src_postgres(dbname = db, host = host,
                       user = user, password = password)
  # Pripravimo tabelo
  tbl.authors <- tbl(conn, "author")

  output$authors <- renderTable({
    # Naredimo poizvedbo
    # x %>% f(y, ...) je ekvivalentno f(x, y, ...)
    t <- tbl.authors %>% filter(author_id > input$min) %>%
      arrange(username) %>% data.frame()
    t$date_joined <- as.character(t$date_joined)
    t$birthday <- as.character(t$birthday)
    # Vrnemo dobljeno razpredelnico
    t
  })

})