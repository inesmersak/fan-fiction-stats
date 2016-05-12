library(shiny)
library(dplyr)
library(RPostgreSQL)
library(plotrix)

source("auth.R")
source("auxiliaryFunctions.R")

shinyServer(function(input, output) {
  # connect to database
  conn <- src_postgres(dbname = db, host = host,
                       user = user, password = password)

  # select tables
  tbl.stories <- tbl(conn, "story")
  tbl.authors <- tbl(conn, "author")
  tbl.characters <- tbl(conn, "character")
  tbl.contains_character <- tbl(conn, "contains_character")


  # RENDER TABLES

  # output$authors <- renderTable({
  #   # filter and order table data
  #   t <- tbl.authors %>% filter(author_id > input$min) %>%
  #     arrange(username) %>% data.frame()
  #   t$date_joined <- as.character(t$date_joined)
  #   t$birthday <- as.character(t$birthday)
  #
  #   # return the table
  #   t
  # })

  output$stories <- renderDataTable({
    t <- tbl.stories %>%
      left_join(
        left_join(tbl.contains_character, tbl.characters, by=c("character"="character_id")),
        by=c("story_id"="story")) %>%
      arrange(desc(hits)) %>%
      filter(hits > input$minViews) %>%
      filter(chapters == input$chapters)
    if (length(input$characters) > 0) {
      t <- t %>% filter(name %in% c(input$characters, NA))
    }
    if (length(input$language) > 0) {
      t <- t %>% filter(language %in% c(input$language, NA))
    }
    t <- t %>% group_by(story_id, title, summary, language, hits, chapters) %>%
      summarise() %>%
      data.frame()
    if (nrow(t) > 0) {
      Encoding(t$title) <- "UTF-8"
      Encoding(t$summary) <- "UTF-8"
      t <- convert_to_encoding(t)
    }
    t
  }, options = list(lengthMenu = c(5, 10, 15, 20), pageLength = 10))


  # RENDER SELECTORS

  numberOfCharactersShown = 100
  output$characterSelector <- renderUI({
    characterNames <- tbl.contains_character %>%
      left_join(tbl.characters, by=c("character"="character_id")) %>%
      group_by(name) %>%
      summarise( appearances = n() ) %>%
      top_n(numberOfCharactersShown, appearances) %>%
      data.frame()
    selectInput("characters", "Characters",
                choices=as.list(characterNames$name), multiple=TRUE)
  })

  output$languageSelector <- renderUI({
    languages <- tbl.stories %>%
      select(language) %>%
      data.frame()
    properlyEncodedLanguages <- as.list(unique(convert_to_encoding(languages)))
    selectInput("language", "Language",
                choices=properlyEncodedLanguages, multiple=TRUE)
  })

  # RENDER PLOTS

  storyTable <- tbl.stories %>% select(language) %>% data.frame()

  output$languagePlot <- renderPlot({
    plotData <- storyTable %>% convert_to_encoding() %>% table()
    lbls <- paste(names(plotData), "\n", plotData, sep="")

    barplot(plotData, names.arg = lbls, xlab = "Language", ylab = "Number of stories", col = "blue",
            main = "Language in fan fictions")

  })

})