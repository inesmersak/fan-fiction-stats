library(shiny)
library(dplyr)
library(RPostgreSQL)

source("auth.R")

convert_to_encoding <-
  function(x, from_encoding = "UTF-8", to_encoding = "cp1250"){

    # names of columns are encoded in specified encoding
    my_names <-
      iconv(names(x), from_encoding, to_encoding)

    # if any column name is NA, leave the names
    # otherwise replace them with new names
    if(any(is.na(my_names))){
      names(x)
    } else {
      names(x) <- my_names
    }

    # get column classes
    x_char_columns <- sapply(x, class)
    # identify character columns
    x_cols <- names(x_char_columns[x_char_columns == "character"])

    # convert all string values in character columns to
    # specified encoding
    x <-
      x %>%
      mutate_each_(funs(iconv(., from_encoding, to_encoding)),
                   x_cols)
    # return x
    return(x)
  }

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
      arrange(desc(hits)) %>%
      filter(name %in% c(input$characters, NA, NA)) %>%
      filter(hits > input$minViews) %>%
      filter(chapters == input$chapters) %>%
      filter(language %in% c(input$language, NA, NA)) %>%
      group_by(story_id, title, summary, language, hits, chapters) %>%
      summarise() %>%
      data.frame()
    if (nrow(t) > 0) {
      Encoding(t$title) <- "UTF-8"
      Encoding(t$summary) <- "UTF-8"
      t <- convert_to_encoding(t)
    }
    t
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

  numberOfCharactersShown = 100
  output$characterSelector <- renderUI({
    characterNames <- tbl.contains_character %>%
      left_join(tbl.characters, by=c("character"="character_id")) %>%
      group_by(name) %>%
      summarise( appearances = n() ) %>%
      top_n(numberOfCharactersShown, appearances) %>%
      data.frame()
    selectInput("characters", "Characters", choices=as.list(characterNames$name), multiple=TRUE)
  })

  output$languageSelector <- renderUI({
    languages <- tbl.stories %>%
      select(language) %>%
      data.frame()
    properlyEncodedLanguages <- as.list(unique(convert_to_encoding(languages)))
    selectInput("language", "Language", choices=properlyEncodedLanguages, multiple=TRUE)
  })

})