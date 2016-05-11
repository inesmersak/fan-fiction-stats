library(shiny)
library(dplyr)
library(RPostgreSQL)

source("auth.R")

shinyServer(function(input, output) {
  # connect to database
  conn <- src_postgres(dbname = db, host = host,
                       user = user, password = password)
  # select tables
  tbl.stories <- tbl(conn, "story")
  tbl.authors <- tbl(conn, "author")
  tbl.characters <- tbl(conn, "character")
  tbl.contains_character <- tbl(conn, "contains_character")

  output$authors <- renderTable({
    # filter and order table data
    t <- tbl.authors %>% filter(author_id > input$min) %>%
      arrange(username) %>% data.frame()
    t$date_joined <- as.character(t$date_joined)
    t$birthday <- as.character(t$birthday)

    # return the table
    t
  })

  output$stories <- renderTable({
    t <- tbl.stories %>%
      left_join(
        left_join(tbl.contains_character, tbl.characters, by=c("character"="character_id")),
        by=c("story_id"="story")) %>%
      filter(name %in% input$characters) %>%
      select(story_id, title, summary) %>%
      data.frame()
  })

  output$characters <- renderTable({
    t <- tbl.characters %>% arrange(name) %>% select(name) %>% data.frame()
    t <- tbl.contains_character %>%
      left_join(tbl.characters, by=c("character"="character_id")) %>%
      group_by(name) %>%
      summarise( appearances = n() ) %>%
      top_n(20, appearances) %>%
      data.frame()
  })

  output$characterSelector <- renderUI({
    characterNames <- tbl.contains_character %>%
      left_join(tbl.characters, by=c("character"="character_id")) %>%
      group_by(name) %>%
      summarise( appearances = n() ) %>%
      top_n(100, appearances) %>%
      data.frame()
    selectInput("characters", "Characters", choices=as.list(characterNames$name), multiple=TRUE)
  })

})