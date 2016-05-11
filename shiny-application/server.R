library(shiny)
library(dplyr)
library(RPostgreSQL)

source("auth.R")

shinyServer(function(input, output) {
  # connect to database
  conn <- src_postgres(dbname = db, host = host,
                       user = user, password = password)
  # select table
  tbl.authors <- tbl(conn, "author")

  output$authors <- renderTable({
    # filter and order table data
    t <- tbl.authors %>% filter(author_id > input$min) %>%
      arrange(username) %>% data.frame()
    t$date_joined <- as.character(t$date_joined)
    t$birthday <- as.character(t$birthday)
    
    # return the table
    t
  })
  
   tbl.characters <- tbl(conn, "character")
   tbl.characters %>% arrange(name) %>% select(name)
  

})