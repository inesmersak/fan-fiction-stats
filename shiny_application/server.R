library(shiny)
library(dplyr)
library(RPostgreSQL)
library(plotrix)
library(ggplot2)
library(gridExtra)

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
  tbl.is_in_category <- tbl(conn, "is_in_category")
  tbl.category <- tbl(conn, "category")
  tbl.language <- tbl(conn, "language")


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
      left_join(
        left_join(tbl.is_in_category, tbl.category, by=c("category"="category_id")),
        by=c("story_id"="story")
      ) %>%
      left_join(tbl.language, by=c("language"="language_id")) %>%
      arrange(desc(hits)) %>%
      filter(hits > input$minViews) %>%
      filter(chapters == input$chapters)
    if (length(input$characters) > 0) {
      t <- t %>% filter(character_name %in% c(input$characters, NA))
    }
    if (length(input$language) > 0) {
      t <- t %>% filter(language_name %in% c(input$language, NA))
    }
    if (length(input$category) > 0) {
      t <- t %>% filter(category_name %in% c(input$category, NA))
    }

    if (input$rating != "All") {
      t <- t %>% filter(rating == input$rating)
    }
    t <- t %>% group_by(story_id, title, summary, language_name, rating, hits, chapters) %>%
      summarise(categories=paste(distinct(category_name), collapse=", "),
                characters=paste(character_name, collapse=", ")) %>%
      data.frame()
    if (nrow(t) > 0) {
      Encoding(t$title) <- "UTF-8"
      Encoding(t$summary) <- "UTF-8"
      t <- convert_to_encoding(t)
    }
  }, options = list(lengthMenu = c(5, 10, 15, 20), pageLength = 10))


  # RENDER SELECTORS

  numberOfCharactersShown = 100
  output$characterSelector <- renderUI({
    characterNames <- tbl.contains_character %>%
      left_join(tbl.characters, by=c("character"="character_id")) %>%
      group_by(character_name) %>%
      summarise( appearances = n() ) %>%
      top_n(numberOfCharactersShown, appearances) %>%
      data.frame()
    selectInput("characters", "Characters",
                choices=as.list(characterNames$character_name), multiple=TRUE)
  })

  output$languageSelector <- renderUI({
    languages <- left_join(tbl.stories, tbl.language, by=c("language"="language_id")) %>%
      select(language_name) %>% data.frame() %>% arrange(language_name)
    properlyEncodedLanguages <- as.list(unique(convert_to_encoding(languages)))
    selectInput("language", "Language",
                choices=properlyEncodedLanguages, multiple=TRUE)
  })

  # RENDER PLOTS


  output$languagePlot <- renderPlot({
    plotData <- left_join(tbl.stories, tbl.language, by=c("language"="language_id")) %>%
      select(language_name) %>% filter(language_name != "English") %>% data.frame()

    ggplot(data=plotData, aes(x=language_name, fill=language_name)) +
      geom_bar() +
      scale_x_discrete(breaks=NULL)
  })


  output$ratingsPlot <- renderPlot({
    plotData <- tbl.stories %>% select(rating) %>% data.frame()

    ratingsPlot <- ggplot(data=plotData, aes(x=rating,  fill=rating)) +
      geom_bar() +
      guides(fill=FALSE)

    plotData <- left_join(tbl.stories, left_join(tbl.category, tbl.is_in_category, by=c("category_id"="category")),
                          by=c("story_id"="story")) %>% select(category_name) %>% data.frame()

    categoryPlot <- ggplot(data=plotData, aes(x=category_name,  fill=category_name)) +
      geom_bar() +
      guides(fill=FALSE)

    grid.arrange(ratingsPlot, categoryPlot, ncol=2)
  })

  output$wordsPlot <- renderPlot({
    storiesData <- tbl.stories %>% select(words) %>% data.frame()
    wordsMean <- mean(storiesData$words)
    plotData <- tbl.stories %>% arrange(words) %>% filter(words <= wordsMean)%>% data.frame()

    ggplot(plotData, aes(x = words)) +
      geom_histogram(colour="white", fill="#00BF7D", binwidth=250) +
      scale_x_continuous(breaks=seq(0, wordsMean, 250)) +
      scale_y_continuous(breaks=seq(0, nrow(storiesData), 1000))
  })

})