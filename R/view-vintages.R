#' View vintages using an interactive dashboard.
#' @param data data.frame containing vintages in long format. Should contain columns
#' 'Name', 'Vintage', 'Date', and 'Value'.
#' @details
#' Plots are generated with `ggplot2` by default. If the (RBA-internal) `ggrba`
#' and/or `arphit` packages are installed, they are offered as additional
#' plotting options.
#' @export
vintage_viewer <- function(data) {
  library(shiny)
  library(ggplot2)

  # Only offer plotting backends that are actually installed. ggplot2 is
  # always available as it is a hard dependency; ggrba/arphit are optional,
  # RBA-internal packages.
  plot_choices <- "ggplot"
  if (requireNamespace("ggrba", quietly = TRUE)) {
    plot_choices <- c(plot_choices, "ggrba")
  }
  if (requireNamespace("arphit", quietly = TRUE)) {
    plot_choices <- c(plot_choices, "arphit")
  }
  default_plotFn <- if ("arphit" %in% plot_choices) "arphit" else plot_choices[1]

  ui <- fluidPage(
    fluidRow(
      column(12,
             titlePanel("timetravelr Vintage Viewer"),
             h5("Hamish Sullivan, 2024")
      )
    ),
    tabsetPanel(
      # Tab 1 - Generate Multi vintage charts for a single series
      tabPanel("Multi-vintage",
               sidebarLayout(
                 sidebarPanel(
                   sliderInput("vintage", "Select Vintage Range:",
                               min = min(data$Vintage), max = max(data$Vintage),
                               value = range(data$Vintage)),
                   selectInput("vintageSelect", "Select specific vintages:",
                               choices = c("None", as.character(unique(data$Vintage))), multiple = TRUE),
                   selectizeInput("vintageRemove", "Remove specific vintages:",
                               choices = as.character(unique(data$Vintage)), multiple = TRUE),
                   selectInput("vintageHighlight", "Highlight specific vintage:",
                               choices = c("None", as.character(unique(data$Vintage))), multiple = TRUE),
                   selectInput("name", "Select Name:",
                               choices = unique(data$Name), selected = unique(data$Name)[1]),
                   selectInput("plotFn", "Plotter:",
                               choices = plot_choices, selected = default_plotFn)
                 ),
                 mainPanel(
                   fluidRow(
                     column(12, plotOutput("plot", height = "600px", width = "600px"))
                   )
                 )
               )
              ),
      # Tab 1 - Generate Multi series charts for a given vintage
      tabPanel("Multi-series",
               sidebarLayout(
                 sidebarPanel(
                   selectInput("vintageSelect_multi", "Select vintage:",
                               choices = c("None", as.character(unique(data$Vintage))),selected = max(data$Vintage)),
                   selectizeInput("name_multi", "Select Names:",
                               choices = unique(data$Name), selected = unique(data$Name)[1], multiple=TRUE),
                   textInput("title_multi", "Graph Title",
                                  value="Vintages of Selected Variables", placeholder="Enter graph title here")
                   ),
                 mainPanel(
                   fluidRow(
                     column(12, plotOutput("plot_multi", height = "600px", width = "600px"))
                   )
                 )
               )
      ),

      # Tab 2 - Generate GIF charts
      tabPanel("Dynamic Charts",
               sidebarLayout(
                 sidebarPanel(
                   sliderInput("vintage", "Select Vintage Range:",
                               min = min(data$Vintage), max = max(data$Vintage),
                               value = range(data$Vintage)),
                   selectInput("name", "Select Name:",
                               choices = unique(data$Name), selected = unique(data$Name)[1]),
                 ),
                 mainPanel(
                   fluidRow(
                     column(12, imageOutput("gif", height = "600px", width = "600px"))
                   )
                 )
               )
               )
    )
  )

  server <- function(input, output) {
    # Define filtered data reactive. This returns a dataframe with a single
    # variable and multiple vintages which is used in static and dynamic plots.
    filtered_data <- reactive({
      out <- data |>
        dplyr::filter(Vintage >= input$vintage[1] & Vintage <= input$vintage[2],
               Name == input$name, !(Vintage %in% input$vintageRemove))
      if (length(input$vintageSelect) > 0) {
        out <- out |>
          dplyr::filter(Vintage %in% input$vintageSelect)
      }
      out
    })

    filtered_data_multi <- reactive({
      data |>
        dplyr::filter(Vintage == input$vintageSelect_multi,
                      (Name %in% input$name_multi))
    })

    # Define highlighted data reactive. This returns a dataframe with a single
    # vintage which is highlighted on static plots.
    highlighted_data <- reactive({
      if (length(input$vintageHighlight) > 0) {
        out <- data |>
          dplyr::filter(Vintage %in% as.Date(input$vintageHighlight),
                        Name == input$name)
      } else {
        out <- NULL
      }
      out
    })

    output$plot <- renderPlot({
      data <- filtered_data()
      var_name <- input$name
      col_palette <- colorspace::qualitative_hcl(length(unique(data$Vintage)), palette="Dark 2")
      if (input$plotFn == "arphit") {
        plt <- arphit::arphitgg() +
          arphit::agg_line(data=data, aes=arphit::agg_aes(x=Date, y=Value, group=Vintage), colour=col_palette) +
          arphit::agg_title(sprintf("Vintages of %s", var_name)) +
          arphit::agg_subtitle(sprintf("From %s to %s", min(data$Vintage), max(data$Vintage)))

        # # Highlight specific vintage, if requested
        highlighted <- highlighted_data()
        if (!is.null(highlighted)) {
          plt <- plt +
            arphit::agg_line(data=highlighted, arphit::agg_aes(x = Date, y = Value, group=Vintage), colour="firebrick")
        }
        return(arphit::agg_draw(plt, directdraw=TRUE))
      }

      # TODO: ggplot and ggrba implementation is WIP.
      if (input$plotFn %in% c("ggplot", "ggrba")) {
        plt <- ggplot(data=data, aes(x = Date, y = Value, colour=Vintage)) +
          geom_line(colour = col_palette) +
          labs(title = sprintf("Vintages of %s", input$name),
               subtitle=sprintf("From %s to %s", input$vintage[1], input$vintage[2]))

        # Highlight specific vintage, if requested
        highlighted <- highlighted_data()
        if (!is.null(highlighted)) {
          print(highlighted)
          plt <- plt +
            geom_line(data=highlighted, aes(x = Date, y = Value, colour = Vintage))
        }

        if (input$plotFn == "ggrba") {
          plt <- plt + ggrba::theme_rba()
        }
        return(plt)
      }
    })

    # Generate multi panel plots
    output$plot_multi <- renderPlot({
      data <- filtered_data_multi()
      graph_title <- input$title_multi
      vintage <- input$vintageSelect_multi
      col_palette <- colorspace::qualitative_hcl(length(unique(data$Name)), palette="Dark 2")
        plt <- arphit::arphitgg() +
          arphit::agg_line(data=data |>
                             dplyr::filter(Vintage == vintage),
                           aes=arphit::agg_aes(x=Date, y=Value, group=Name), colour=col_palette) +
          arphit::agg_title(graph_title) +
          arphit::agg_subtitle(sprintf("%s vintage", unique(data$Vintage))) +
          arphit::agg_legend()
        return(arphit::agg_draw(plt, directdraw=TRUE))
    })

    output$gif <- renderImage({
      vintage_animation_gif(filtered_data())
    },deleteFile=TRUE)

  }
  shinyApp(ui = ui, server = server,)
}


#' Create an animated plot of the vintages over time.
#' @param data data.frame containing data of a single variable in long format.
#' @return gganimate/ggplot object.
#' @details
#' Uses the `ggrba` theme if the (RBA-internal) `ggrba` package is installed,
#' falling back to `ggplot2::theme_minimal()` otherwise.
#' @export
vintage_animation <- function(data) {
  var_name <- unique(data$Name)
  plt <- ggplot(data=data, aes(x = Date, y = Value)) +
    geom_line(colour = "black") +
    labs(title = var_name,
         subtitle="{frame_time}")

  if (requireNamespace("ggrba", quietly = TRUE)) {
    plt <- plt + ggrba::theme_rba()
  } else {
    plt <- plt + theme_minimal()
  }

  plt <- plt +
    gganimate::transition_time(Vintage) +
    gganimate::ease_aes("linear")
  gganimate::animate(plt)
}

vintage_animation_gif <- function(data) {
  ani <- vintage_animation(data)
  gganimate::anim_save("temp.gif", animation = ani)
  # Return a list containing the filename
  list(src = "temp.gif",
       contentType = 'image/gif')
}
