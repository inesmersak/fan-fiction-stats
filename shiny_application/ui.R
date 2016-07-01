library(shiny)
library(DT)

RATINGS <- c("All",
             "Teen And Up Audiences",
             "General Audiences",
             "Explicit",
             "Mature",
             "Not Rated")

CATEGORIES <- c("M/M", "F/M", "Gen", "Multi", "F/F", "Other")
CATEGORIES <- setNames(seq(1,length(CATEGORIES)), CATEGORIES)


shinyUI(navbarPage("Harry Potter Fan Fiction",
  theme="bootstrap-sandstone.css",
  inverse = TRUE,

  # BROWSE STORIES TAB #
  tabPanel("Browse stories",
    sidebarLayout(
      sidebarPanel(width=2,
        uiOutput("characterSelector"),
        uiOutput("languageSelector"),
        textOutput("someText"),
        selectInput("rating", label = "Rating",
          choices = RATINGS, selected = 1),
        selectInput("category", label = "Category",
          choices = CATEGORIES, multiple = TRUE),
        # numericInput("chapters",
        #   label = "Number of chapters",
        #   value = 0,
        #   min = 0
        # ),
        checkboxInput("completed", label="Completed only", FALSE),
        sliderInput("chapters",
                    "Number of chapters:",
                    min = 1,
                    max = 500,
                    value = c(1,1000)),
        sliderInput("minViews",
                    "Minimal number of views:",
                    min = 0,
                    max = 200000,
                    value = 1000)
      ),

      mainPanel(width=10,
        fluidRow(
          column(6, DT::dataTableOutput("stories")),
          column(6, uiOutput("story"))
        )
      )


    )
  ),

  # BROWSE AUTHORS TAB #
  tabPanel("Search by author",
    sidebarLayout(
     sidebarPanel(width=3,
                  uiOutput("authorSelector"),
                  numericInput("authorStoriesSelector",
                               label = "Number of author's stories to show",
                               value = 7,
                               min = 1
                  )

     ),

      mainPanel(width=9,
        fluidRow(
         column(8, uiOutput("authorStories"))
        )
      )
    )
  ),

  # STATISTICS TAB #
  tabPanel("Statistics",
    # sidebarLayout(
    #   sidebarPanel(width=2,
    #     selectInput("property", label = "Compare by",
    #                 choices = list("Author" = 1, "Language" = 2, "Number of words" = 3),
    #                 selected = 1)
    #   ),

    fluidRow(
      column(8, offset=2,
        h2("Language"),
        p("While Archive of Our Own supports 64 languages, not all of them are used in the Harry Potter fandom.
          The graph underneath shows the number of stories written in each language, save for English, which is
          by far the most popular."),
        p(uiOutput("mostUsedLanguage"),
        uiOutput("leastUsedLanguage")),
        br(),
        plotOutput("languagePlot"),
        h2("Popular characters"),
        plotOutput("charactersPlot"),
        br(),
        h2("Other statistics")
      )
    ),

    fluidRow(
      column(2, offset=2,
             uiOutput("databaseStatistics")),
      column(6,
             plotOutput("ratingsPlot"))
    ),

    fluidRow(
      column(8, offset=2,
             plotOutput("catWarnPlot"),
             plotOutput("timePlot"),
             plotOutput("wordsPlot"))
    )


    # )
  ),


  # INFO TAB #
  tabPanel("Info",
    mainPanel(
      navlistPanel(
        tabPanel("Source and tools",
          fluidRow(
            column(10, offset=1,
              h3("Source"),
              p("Data shown in this application was retrieved from", a("Archive of Our Own", href="http://archiveofourown.org/", target="_blank"), "."),
              p("Link to our BitBucket repository:",
                a("Emayla/fan-fiction-stats", href="http://bitbucket.org/Emayla/fan-fiction-stats", target="_blank"), "."),
              h3("Tools"),
              p("This application was built in order to help people choose a fan fiction to read. The data was scraped from",
                a("Archive of Our Own", href="http://archiveofourown.org/", target="_blank"),
                "using Python's",
                a("Beautiful Soup", href="https://www.crummy.com/software/BeautifulSoup/bs4/doc/", target="_blank"), "and",
                a("requests", href="http://docs.python-requests.org/en/master/", target="_blank"), "libraries."),
              p("All the data collected is stored in a PostgreSQL database, which contains information on stories, authors, characters and relationships, fandoms, etc.",
                "The database was created and filled using Python's",
                a("psycopg2", href="https://pypi.python.org/pypi/psycopg2", target="_blank"),
                "module, which is used to communicate with a PostgreSQL database."),
              p("The Shiny application is then used to present the data in an intuitive, clean way.",
                code("RPostgreSQL"), "library is used to retrieve data from the database, while",
                code("dplyr"), "library is used to manage the data retrieved.",
                "The graphs are drawn using the", code("ggplot2"), "and", code("gridExtra"), "libraries and the",
                code("DT"), "library is used to render the stories datatable.")
            )
          )
        ),
        tabPanel("Authors",
                fluidRow(
                  column(10, offset=1,
                     h3("Authors"),
                     p("This application was made as part of a project for the subject \'Osnove podatkovnih baz\' in the 2015/16 spring term."),
                     enc2utf8("Matic Oskar Hajšen, Ines Meršak.")
                  )
                )
        )
      )
    )
  )

))