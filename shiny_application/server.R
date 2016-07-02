library(shiny)
library(dplyr)
library(RPostgreSQL)
#library(plotrix)
library(ggplot2)
library(gridExtra)
library(DT)

source("auth_public.R")
source("auxiliaryFunctions.R")

shinyServer(function(input, output, session) {
  # connect to database
  drv <- dbDriver("PostgreSQL")
  conn <- dbConnect(drv, dbname = db, host = host,
                       user = user, password = password)

  dbGetQuery(conn, "SET CLIENT_ENCODING TO 'utf8'; SET NAMES 'utf8'")

  cancel.onSessionEnded <- session$onSessionEnded(function() {
    dbDisconnect(conn)
  })

  # RENDER STORIES

  storyData <- reactive({
    query <-"SELECT DISTINCT title, language_name, chapters, completed, hits, story_id
            FROM story
            JOIN contains_character ON story_id=story
            JOIN is_in_category ON story_id=is_in_category.story
            JOIN language ON language=language_id
            WHERE"
    query <- paste(query, "hits >=", input$minViews)
    # AND language_name='Spanish' AND character IN (1,2,7)
    query <- paste0(query, " AND chapters>=", input$chapters[1])
    query <- paste0(query, " AND chapters<=", input$chapters[2])

    if (length(input$characters) > 0) {
      query <- paste0(query, "AND character IN (",
                     paste(c(input$characters), collapse=", "),
                     ")")
    }
    if (length(input$language) > 0) {
      query <- paste0(query, " AND language IN (",
                      paste(c(input$language), collapse=", "),
                      ")")
    }
    if (length(input$category) > 0) {
      query <- paste0(query, " AND category IN (",
                      paste(c(input$category), collapse=", "),
                      ")")
    }
    if (input$rating != "All") {
      query <- paste0(query, " AND rating='", input$rating, "'")
    }
    if (input$completed) {
      query <- paste(query, "AND completed=true")
    }

    query <-paste(query, "GROUP BY story_id, title, language_name, chapters, completed, hits
                          ORDER BY hits DESC, title ASC")

    t <- dbGetQuery(conn, query) %>% data.frame()
    if (nrow(t) > 0) {
      # t$summary <- as.character(t$summary)
      Encoding(t$title) <- "UTF-8"
      # Encoding(t$summary) <- "UTF-8"
    }
    t
  })

  output$stories <- DT::renderDataTable({
    if (nrow(storyData()) > 0) {
      data <- select(storyData(), title, language_name, completed, chapters)
      names(data) <- c("Title", "Language", "Completed?", "# of chapters")
      datatable(data,
                options = list(
                  pageLength = 10,
                  lengthMenu = c(10, 15, 20)),
                selection="single"
      ) %>% formatStyle(
        'Title',
        target = 'row',
        cursor = 'pointer')
    }
  })


  output$story <- renderUI({
    if (nrow(storyData()) > 0 && length(input$stories_rows_selected) > 0) {
      storyRow <- storyData()[input$stories_rows_selected,]
      storyInfo <- dbGetQuery(conn,
                              build_sql("SELECT story_id, title, username, summary, language_name, rating, hits,
                                        kudos, comments, words, chapters, completed, date_published,
                                        string_agg(DISTINCT fandom_name, \', \') AS fandoms,
                                        string_agg(DISTINCT warning_description, \', \') AS warnings,
                                        string_agg(DISTINCT character_name, \', \') AS characters,
                                        string_agg(DISTINCT category_name, \', \') AS categories FROM story
                                        JOIN author ON written_by=author_id
                                        JOIN contains_character ON story_id=story
                                        JOIN character ON character=character_id
                                        JOIN is_in_category ON story_id=is_in_category.story
                                        JOIN category ON category=category_id
                                        JOIN language ON language=language_id
                                        JOIN contains_fandom ON story_id=contains_fandom.story
                                        JOIN fandom ON fandom=fandom_id
                                        JOIN has_warning ON story_id=has_warning.story
                                        JOIN warning ON warning=warning_id
                                        WHERE story_id=", storyRow$story_id,
                                        " GROUP BY story_id, title, username, summary, language_name, date_published,
                                        rating, hits, kudos, comments, words, chapters, completed")) %>% data.frame()
      relationshipInfo <- dbGetQuery(conn,
                                     build_sql("SELECT story, string_agg(DISTINCT relationship, \', \') AS relationships FROM
                                              (SELECT story, c1.character_name || \'/\' || c2.character_name AS relationship
                                              FROM contains_relationship
                                              LEFT JOIN character c1 ON person_1=c1.character_id
                                              LEFT JOIN character c2 ON person_2=c2.character_id
                                              WHERE story=", storyRow$story_id,
                                              " ) AS rl
                                              GROUP BY story")) %>% data.frame()
      Encoding(storyInfo$title) <- "UTF-8"
      if (length(storyInfo$summary) > 0) {
        Encoding(storyInfo$summary) <- "UTF-8"
      }
      if (length(storyInfo$characters) > 0) {
        Encoding(storyInfo$characters) <- "UTF-8"
      }
      if (length(storyInfo$fandoms) > 0) {
        Encoding(storyInfo$fandoms) <- "UTF-8"
      }
      Encoding(storyInfo$username) <- "UTF-8"
      if (length(relationshipInfo$relationships) > 0) {
        Encoding(relationshipInfo$relationships) <- "UTF-8"
      }
      title <- h2(storyInfo$title)
      author <- h4("Written by:", storyInfo$username)
      mainInfo <- p(strong("Date published: "), format(storyInfo$date_published, format="%d %B, %Y"), br(),
                    strong("Language: "), storyInfo$language_name, br(),
                    strong("Rating:"), storyInfo$rating)
      warnings <- p(strong("Warnings"), br(), storyInfo$warnings)
      categories <- p(strong("Categories"), br(), storyInfo$categories)
      link <- a("Click here to read the story", href=paste0("http://archiveofourown.org/works/", storyInfo$story_id), target="_blank")
      summary <- p(strong("Summary"), br(), storyInfo$summary, br(), link)
      statistics <- p(strong("Statistics"), br(),
                      "Words: ", storyInfo$words, br(),
                      "Chapters: ", storyInfo$chapters, br(),
                      "Views: ", storyInfo$hits, br(),
                      "Favourites: ", storyInfo$kudos, br(),
                      "Comments: ", storyInfo$comments, br())

      characters <- p(strong("Characters"), br(), storyInfo$characters)
      relationships <- p(strong("Relationships"), br(), relationshipInfo$relationships)
      fandoms <- p(strong("Fandoms"), br(), storyInfo$fandoms)
      HTML(paste(title, author, mainInfo, warnings, categories, summary, characters, relationships, fandoms, statistics))
    }
  })

  # RENDER AUTHORS

  storiesToHTML <- function(authorStories, n) {
    n=min(nrow(authorStories),n)
    stories <- c(n)
    for (i in 1:n) {
      title <- h4(authorStories$title[i])
      link <- a("Click here to read the story", href=paste0("http://archiveofourown.org/works/", authorStories$story_id[i]), target="_blank")
      summary <- ""
      if (!is.na(authorStories$summary[i])) {
        summary <- authorStories$summary[i]
      }
      storysum <- p(summary, br(), link)
      stories[i] <- HTML(paste(title, storysum))
    }
    storiesHTML <- HTML(paste0(c(stories)))
    return(storiesHTML)
  }

  output$authorStories <- renderUI({
    if (length(input$author) > 0) {
      info <- dbGetQuery(conn,
          build_sql("SELECT * FROM author
                   WHERE author_id=", input$author)) %>% data.frame()
      Encoding(info$username) <- "UTF-8"
      Encoding(info$location) <- "UTF-8"
      username <- h2(info$username)
      date_joined <- HTML(paste(strong("Date joined:"), format(info$date_joined, format="%d %B, %Y"), br()))
      location <- ""
      if (!is.na(info$location)) {
        location <- HTML(paste(strong("Location:"), info$location, br()))
      }
      birthday <- ""
      if (!is.na(info$birthday)) {
        birthday <- HTML(paste(strong("Birthday:"), format(info$birthday, format="%d %B, %Y"), br()))
      }
      stories <- dbGetQuery(conn,
          build_sql("SELECT * FROM
                    story WHERE written_by=", input$author,
                    " GROUP BY story_id ORDER BY hits DESC, title ASC")) %>% data.frame()
      Encoding(stories$title) <- "UTF-8"
      Encoding(stories$summary) <- "UTF-8"
      numberOfStories <- h2("Stories written: ", nrow(stories))
      HTML(paste(username, p(date_joined, birthday, location),
                 numberOfStories,
                 #HTML(paste(c(stories$title), collapse=", "))
                 storiesToHTML(stories, input$authorStoriesSelector)
                 ))
    }
  })

  # RENDER SELECTORS

  numberOfCharactersShown = as.integer(100)
  output$characterSelector <- renderUI({
    characterNames <- dbGetQuery(conn,
       build_sql("SELECT character_name, character_id, COUNT(*) AS appearances
       FROM contains_character
       JOIN character ON character=character_id
       GROUP BY character_name, character_id
       ORDER BY appearances DESC
       LIMIT ", numberOfCharactersShown)) %>% data.frame()
    Encoding(characterNames$character_name) <- "UTF-8"
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

  output$authorSelector <- renderUI({
    authors <- dbGetQuery(conn,
      "SELECT author_id, username FROM author ORDER BY username ASC") %>% data.frame()
    Encoding(authors$username)<- "UTF-8"
    authorNames <- as.vector(authors$username)
    authorIds <- as.vector(authors$author_id)
    selectInput("author", "Author",
                choices=setNames(authorIds, authorNames), multiple=FALSE, size=30, selectize=FALSE)
  })


  # RENDER STATISTICS
  languagesUsed <- dbGetQuery(conn, "SELECT language_name, COUNT(*) AS language_count
                              FROM story LEFT JOIN language ON language=language_id
                              GROUP BY language_name ORDER BY language_count DESC") %>% data.frame()
  output$mostUsedLanguage <- renderUI({
    mostUsed <- languagesUsed %>% top_n(1, language_count) %>%
      select(language_name, language_count)
    mostUsedStr <- paste("Most used language: ", mostUsed$language_name, ", used in ",
                         mostUsed$language_count, " fan fictions.", sep="")
    HTML(mostUsedStr, end="<br/>")
  })
  output$leastUsedLanguage <- renderUI({
    leastUsed <- languagesUsed %>% top_n(1, -language_count) %>% select(language_name, language_count)
    leastUsedStr <- paste("Least used language: ", leastUsed$language_name, ", used in ",
                          leastUsed$language_count, " fan fiction.", sep="")
    HTML(paste(leastUsedStr,"<br/>"))
  })

  output$databaseStatistics <- renderUI({
    stories <- dbGetQuery(conn, "SELECT * FROM story") %>% data.frame() %>% nrow()
    authors <- dbGetQuery(conn, "SELECT * FROM author") %>% data.frame() %>% nrow()
    characters <- dbGetQuery(conn, "SELECT * FROM character") %>% data.frame() %>% nrow()
    relationships <- dbGetQuery(conn, "SELECT DISTINCT * FROM relationship") %>% data.frame() %>% nrow()
    fandoms <- dbGetQuery(conn, "SELECT * FROM fandom") %>% data.frame() %>% nrow()
    title <- h4("Database statistics")
    stats <- p("Number of stories: ", stories, br(),
               "Number of authors: ", authors, br(),
               "Number of characters: ", characters, br(),
               "Number of relationships: ", relationships, br(),
               "Number of fandoms:", fandoms, br())
    HTML(paste(title, stats))
  })

  # RENDER PLOTS

  output$languagePlot <- renderPlot({
    plotData <- dbGetQuery(conn,
        "SELECT language_name, COUNT(*) AS count_language
        FROM story
        JOIN language ON language=language_id
        WHERE language_name!='English'
        GROUP BY language_name") %>% data.frame()

    ggplot(data=plotData,
           aes(x=language_name, y=count_language, fill=language_name)) +
      geom_bar(stat="identity") +
      scale_x_discrete(breaks=NULL) +
      labs(x="Language", y="Number of stories", fill="Languages")
  })


  output$ratingsPlot <- renderPlot({
    plotData <- dbGetQuery(conn,
                           "SELECT rating, COUNT(*) AS count_rating
                           FROM story
                           GROUP BY rating") %>% data.frame()
    ratingsPlot <- ggplot(plotData, aes(x=factor(1), y = count_rating, fill = rating)) +
      geom_bar(stat = "identity", width = 1) + coord_polar(theta = "y") +
      ylab("") +
      labs(x=" ", y=" ", fill="Ratings")
    # + theme(legend.position="bottom")
    # ratingsPlot <- ggplot(data=plotData,
    #                       aes(x=factor(1), y=count_rating, fill=rating)) +
    #   geom_bar(stat="identity") +
    #   guides(fill=FALSE)
    ratingsPlot
  })

  output$catWarnPlot <- renderPlot({
    plotData <- dbGetQuery(conn,
        "SELECT warning_description, COUNT(*) AS count_warning
        FROM has_warning JOIN warning ON warning=warning_id
        GROUP BY warning_description") %>% data.frame()
    warningsPlot <- ggplot(plotData, aes(x=warning_description, y = count_warning, fill = warning_description)) +
      geom_bar(stat = "identity")+
      scale_x_discrete(breaks=NULL)+
      labs(x="Warning", y="Number of stories", fill="Warnings")

    plotData <- dbGetQuery(conn,
       "SELECT category_name, COUNT(*) AS count_category FROM story
       JOIN is_in_category ON story_id=story
       JOIN category ON category=category_id
       GROUP BY category_name") %>% data.frame()

    categoryPlot <- ggplot(data=plotData,
                           aes(x=category_name, y=count_category, fill=category_name)) +
      geom_bar(stat="identity") +
      guides(fill=FALSE) +
      labs(x="Category", y="Number of stories")

    grid.arrange(categoryPlot, warningsPlot, ncol=2)
  })

  output$wordsPlot <- renderPlot({
    storiesData <- dbGetQuery(conn, "SELECT words FROM story") %>% data.frame()
    wordsMean <- mean(storiesData$words)
    plotData <- storiesData %>% arrange(words) %>% filter(words <= wordsMean)%>% data.frame()

    ggplot(plotData, aes(x = words)) +
      geom_histogram(colour="white", fill="#00BF7D", binwidth=250) +
      scale_x_continuous(breaks=seq(0, wordsMean, 250)) +
      scale_y_continuous(breaks=seq(0, nrow(storiesData), 1000)) +
      labs(x="Number of words", y="Number of stories")
  })

  output$charactersPlot <- renderPlot({
    numberOfCharactersPlotted = as.integer(10)
    characterAppearances <- dbGetQuery(conn,
       build_sql("SELECT character_name, COUNT(*) AS appearances FROM contains_character
       JOIN character ON character=character_id
       GROUP BY character_name
       ORDER BY appearances DESC
       LIMIT ", numberOfCharactersPlotted)) %>% data.frame()

    # allAppearances = sum(characterAppearances$appearances)
    # topAppearances = sum(plotData$appearances)

    # plotData[nrow(plotData) + 1,] <- c("Others", allAppearances-topAppearances)
    # plotData$appearances <- as.numeric(as.character(plotData$appearances))
    # plotData <- arrange(plotData,appearances)
    plotData <- characterAppearances

    ggplot(data=plotData, aes(x=character_name, y=appearances, fill=character_name)) +
      geom_bar(stat="identity") +
      # coord_cartesian(ylim=c(0, (allAppearances-topAppearances)/4)) +
      guides(fill=FALSE) + 
      labs(x="Character", y="Number of appearances")
  })
  
  output$timePlot <- renderPlot({
    timeData <- dbGetQuery(conn, "SELECT date_part('year', date_published) AS year, 
                                  COUNT(*) AS count_date FROM story 
                                  WHERE date_part('year', date_published) > 1970
                                  GROUP BY year 
                                  ORDER BY year ASC") %>% data.frame()
    yearMax <- max(timeData$year)
    countMax <- max(timeData$count_date)
    
    timePlot <- ggplot(data=timeData, aes(x=year, y=count_date, group=1)) +
      geom_line(color="green2", size=1.5) +
      geom_point(size=2) + 
      scale_x_continuous(breaks=seq(0, yearMax, 1)) +
      scale_y_continuous(breaks=seq(0, countMax, 2500)) +
      labs(x="Year", y="Number of stories published")
    timePlot
  })

})