library(shiny)

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
          choices = list(),
          selected = 1),
        selectInput("category", label = "Category",
          choices = list("Choice 1" = 1, "Choice 2" = 2, "Choice 3" = 3),
          selected = 1),
        numericInput("chapters",
          label = "Number of chapters",
          value = 1,
          min = 1
        ),
        # test #
        sliderInput("minViews",
                    "Minimal number of views:",
                    min = 0,
                    max = 200000,
                    value = 1000)
      ),

      mainPanel(
        tableOutput("stories")
      )


    )
  ),


  # STATISTICS TAB #
  tabPanel("Statistics",
    sidebarLayout(
      sidebarPanel(width=3,
        selectInput("property", label = "Compare by",
                    choices = list("Author" = 1, "Language" = 2, "Number of words" = 3),
                    selected = 1)
      ),

      mainPanel(
        "Lots of plotting."
      )
    )
  ),


  # INFO TAB #
  tabPanel("Info",
    mainPanel(
      navlistPanel(
        tabPanel("Source and tools",
          a("Archive of Our Own", href="http://archiveofourown.org/", target="_blank")),
        tabPanel("Authors",
                 "We are cool.")
      )
    )
  )

))