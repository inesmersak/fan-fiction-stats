library(shiny)
library(dplyr)
library(RPostgreSQL)
library(plotrix)
library(ggplot2)
library(gridExtra)

source("auth_public.R")
source("auxiliaryFunctions.R")

shinyServer(function(input, output) {
  # connect to database
  drv <- dbDriver("PostgreSQL")
  conn <- dbConnect(drv, dbname = db, host = host,
                       user = user, password = password)


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
    query <-"SELECT DISTINCT title, language_name, hits, story_id
            FROM story
            JOIN contains_character ON story_id=story
            JOIN is_in_category ON story_id=is_in_category.story
            JOIN language ON language=language_id
            WHERE"
    query <- paste(query, "hits >=", input$minViews)
    # AND language_name='Spanish' AND character IN (1,2,7)

    if (input$chapters > 0) {
      query <- paste0(query, " AND chapters=", input$chapters)
    }
    if (length(input$characters) > 0) {
      query <- paste0(query, "AND character IN (",
                     paste(c(input$characters), collapse=", "),
                     ")")
    }
    if (length(input$language) > 0) {
      query <- paste0(query, " AND language=", input$language)
    }
    if (length(input$category) > 0) {
      query <- paste0(query, " AND category IN (",
                      paste(c(input$category), collapse=", "),
                      ")")
    }
    if (input$rating != "All") {
      query <- paste0(query, " AND rating='", input$rating, "'")
    }

    query <-paste(query, "GROUP BY story_id, title, language_name, hits
                          ORDER BY hits DESC, title ASC")

    t <- dbGetQuery(conn, query) %>% data.frame()

    if (nrow(t) > 0) {
      Encoding(t$title) <- "UTF-8"
      t <- convert_to_encoding(t)
    }
  }, options = list(lengthMenu = c(5, 10, 15, 20), pageLength = 10, selection="single"))


  # RENDER SELECTORS

  numberOfCharactersShown = 100
  output$characterSelector <- renderUI({
    characterNames <- dbGetQuery(conn,
       "SELECT character_name, character_id, COUNT(*) AS appearances
       FROM contains_character
       JOIN character ON character=character_id
       GROUP BY character_name, character_id
       ORDER BY appearances DESC
       LIMIT 100") %>% data.frame()
    charNames <- as.vector(characterNames$character_name)
    charIds <- as.vector(characterNames$character_id)
    selectInput("characters", "Characters",
                choices= setNames(charIds, charNames), multiple=TRUE)
  })

  output$languageSelector <- renderUI({
    languages <- dbGetQuery(conn,
        "SELECT language_name, language_id
        FROM story
        LEFT JOIN language ON language=language_id
        GROUP BY language_name, language_id
        ORDER BY language_name") %>% data.frame()
    langNames <- as.vector(languages$language_name)
    langIds <- as.vector(languages$language_id)
    selectInput("language", "Language",
                choices=setNames(langIds, langNames), multiple=TRUE)
  })
  #
  #
  # # RENDER STATISTICS
  #
  # languagesUsed <- left_join(tbl.stories, tbl.language, by=c("language"="language_id")) %>%
  #   group_by(language_name) %>% summarise(stories=n())
  # output$mostUsedLanguage <- renderUI({
  #   mostUsed <- languagesUsed %>% top_n(1, stories) %>%
  #     select(language_name, stories) %>% data.frame()
  #   mostUsedStr <- paste("Most used language: ", mostUsed$language_name, ", used in ",
  #                        mostUsed$stories, " fan fictions.", sep="")
  #   HTML(mostUsedStr, end="<br/>")
  # })
  # output$leastUsedLanguage <- renderUI({
  #   leastUsed <- languagesUsed %>% top_n(1, -stories) %>%
  #     select(language_name, stories) %>% data.frame()
  #   leastUsedStr <- paste("Least used language: ", leastUsed$language_name, ", used in ",
  #                         leastUsed$stories, " fan fictions.", sep="")
  #   HTML(paste(leastUsedStr,"<br/>"))
  # })
  #
  #
  # # RENDER PLOTS
  #
  #
  # output$languagePlot <- renderPlot({
  #   plotData <- left_join(tbl.stories, tbl.language, by=c("language"="language_id")) %>%
  #     select(language_name) %>% filter(language_name != "English") %>% data.frame()
  #
  #   ggplot(data=plotData, aes(x=language_name, fill=language_name)) +
  #     geom_bar() +
  #     scale_x_discrete(breaks=NULL)
  # })
  #
  #
  # output$ratingsPlot <- renderPlot({
  #   plotData <- tbl.stories %>% select(rating) %>% data.frame()
  #
  #   ratingsPlot <- ggplot(data=plotData, aes(x=rating,  fill=rating)) +
  #     geom_bar() +
  #     guides(fill=FALSE)
  #
  #   plotData <- left_join(tbl.stories, left_join(tbl.category, tbl.is_in_category, by=c("category_id"="category")),
  #                         by=c("story_id"="story")) %>% select(category_name) %>% data.frame()
  #
  #   categoryPlot <- ggplot(data=plotData, aes(x=category_name,  fill=category_name)) +
  #     geom_bar() +
  #     guides(fill=FALSE)
  #
  #   grid.arrange(ratingsPlot, categoryPlot, ncol=2)
  # })
  #
  # output$wordsPlot <- renderPlot({
  #   storiesData <- tbl.stories %>% select(words) %>% data.frame()
  #   wordsMean <- mean(storiesData$words)
  #   plotData <- tbl.stories %>% arrange(words) %>% filter(words <= wordsMean)%>% data.frame()
  #
  #   ggplot(plotData, aes(x = words)) +
  #     geom_histogram(colour="white", fill="#00BF7D", binwidth=250) +
  #     scale_x_continuous(breaks=seq(0, wordsMean, 250)) +
  #     scale_y_continuous(breaks=seq(0, nrow(storiesData), 1000))
  # })
  #
  # output$charactersPlot <- renderPlot({
  #   characterAppearances <- tbl.contains_character %>%
  #     left_join(tbl.characters, by=c("character"="character_id")) %>%
  #     group_by(character_name) %>%
  #     summarise( appearances = n() )
  #
  #   numberOfCharactersPlotted = 10
  #   plotData <- characterAppearances %>% top_n(numberOfCharactersPlotted, appearances) %>%
  #     select(character_name, appearances) %>% data.frame()
  #
  #   characterAppearances <- data.frame(characterAppearances)
  #
  #   allAppearances = sum(characterAppearances$appearances)
  #   topAppearances = sum(plotData$appearances)
  #
  #   plotData[nrow(plotData) + 1,] <- c("Others", allAppearances-topAppearances)
  #   plotData$appearances <- as.numeric(as.character(plotData$appearances))
  #   plotData <- arrange(plotData,appearances)
  #
  #   ggplot(data=plotData, aes(x=character_name, y=appearances, fill=character_name)) +
  #     geom_bar(stat="identity") +
  #     coord_cartesian(ylim=c(0, (allAppearances-topAppearances)/4)) +
  #     guides(fill=FALSE)
  # })

})