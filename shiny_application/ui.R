library(shiny)

RATINGS <- c("All",
             "Teen And Up Audiences",
             "General Audiences",
             "Explicit",
             "Mature",
             "Not Rated")

CATEGORIES <- c("M/M", "F/M", "Gen", "Multi", "F/F", "Other")


shinyUI(navbarPage("Harry Potter Fan Fiction",
  theme="bootstrap-sandstone.css",
  inverse = TRUE,

  # BROWSE TAB #
  tabPanel("Browse stories",
    sidebarLayout(
      sidebarPanel(width=3,
        uiOutput("characterSelector"),
        uiOutput("languageSelector"),
        textOutput("someText"),
        selectInput("rating", label = "Rating",
          choices = RATINGS, selected = 1),
        selectInput("category", label = "Category",
          choices = CATEGORIES, multiple = TRUE),
        numericInput("chapters",
          label = "Number of chapters",
          value = 0,
          min = 0
        ),
        sliderInput("minViews",
                    "Minimal number of views:",
                    min = 0,
                    max = 200000,
                    value = 1000)
      ),

      mainPanel(
        dataTableOutput("stories")
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
      column(10, offset=1,
        h2("Language"),
        p("While Archive of Our Own supports 64 languages, not all of them are used in the Harry Potter fandom.
          The graph underneath shows the number of stories written in each language, save for English, which is
          by far the most popular."),
        p(htmlOutput("mostUsedLanguage"),
        htmlOutput("leastUsedLanguage")),
        br(),
        plotOutput("languagePlot"),
        h2("Popular characters"),
        plotOutput("charactersPlot"),
        br(),
        h2("Other statistics"),
        plotOutput("ratingsPlot"),
        br(),
        plotOutput("wordsPlot")
      )
    )
    # )
  ),


  # INFO TAB #
  tabPanel("Info",
    mainPanel(
      navlistPanel(
        tabPanel("Source and tools",
          a("Archive of Our Own", href="http://archiveofourown.org/", target="_blank")),
        tabPanel("Authors",
                 "Matic Oskar Hajšen, Ines Meršak.")
      )
    )
  )

))