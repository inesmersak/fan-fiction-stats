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
    t <- t %>% group_by(story_id, title, summary, language_name, rating, hits, chapters, category_name) %>%
      summarise() %>%
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
    languages <- tbl.language %>%
      select(language_name) %>%
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

    barplot(plotData, names.arg = lbls, xlab = "Language", ylab = "Number of stories", col = "limegreen",
            main = "Language in fan fictions")

  })


  output$ratingsPlot <- renderPlot({
    plotData <- tbl.stories %>% select(rating) %>% data.frame() %>% table()
    lbls <- paste(names(plotData), "\n", plotData, sep="")

    pie3D(plotData, labels = lbls, explode = 0.1, main = "Ratings")
  })

  output$wordsPlot <- renderPlot({
    plotData <- tbl.stories %>% arrange(words) %>% select(words) %>% data.frame()
    plotData <- c(plotData[,1])
    bins <- seq(min(plotData), max(plotData), length.out = 100)
    # plotData <- c(10,20,25,37,100,1921,543,29,46,786,1123)
    numberofStories <- 2000

    # draw the histogram with the specified number of bins
    hist(plotData, ylim=c(0,2000), breaks=10, xlim=c(min(plotData), 10000), col = 'darkgray', border = 'white')
  })

})