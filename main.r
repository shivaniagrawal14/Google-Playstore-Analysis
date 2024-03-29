library(tidyverse)
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(tm)
library(stringr)
library(scales)
library(DT)
library(tidyr)
library(olsrr)
library(growfunctions)
library(caret)

#Setting the directory and setting the path.
setwd(choose.dir())
getwd()

#Reading the .csv file.
app<-read.csv("googleplaystore1.csv")

#Defines the various attributes of the coloumns.
str(app)
#Gives the count of number of rows and columns present in the dataset.
paste("No of ObserVation Is",nrow(app))
paste("No of Variable Is",ncol(app))

#provides the statistics of the dataset
summary(app)

# Data Preprocessing for Rating column.
app$Rating<-ifelse(is.na(app$Rating),mean(app$Rating,na.rm=TRUE),app$Rating)
app$Rating= round(app$Rating, digits=1)
summary(app$Rating)
summary (app)

# Data Preprocessing for Type column.
summary(app$Type)
app$Type<-  str_replace(app$Type, "NaN", "Free")
app$Type <- as.factor(app$Type)
summary(app)
app$Category= as.factor(app$Category)
# Data Cleaning for Size column.
app$Size<-gsub("M","",app$Size)
app$Size<-gsub("k","",app$Size)
app$Size<-as.numeric(app$Size)
head(app$Size)
unique(app$Size)
# Data Cleaning for Price column.
app$Price<- str_replace(app$Price,"[$]","")
app$Price = as.numeric(app$Price)
summary(app$Price)

# Data Cleaning for Installs column.
app$Installs<-gsub("[,]","",app$Installs)
app$Installs<-gsub("[+]","",app$Installs)
app$Installs <- as.factor(app$Installs)
head(app$Installs)

# Data Cleaning for Content.Rating column.
summary(app$Content.Rating)
indices= which(app$Content.Rating == "Unrated")
indices

app= app[c(-7313, -8267),]
app$Content.Rating <- as.factor(app$Content.Rating)
summary(app$Content.Rating)
unique(app$Content.Rating)

# Removing the columns.
# They have been removed as they are not giving me enough information which is required
#in my prediction analysis
# Removing Columns like: Android.ver, Current.Ver, Last.Updated. Also
# As category is similar to Genres. hence removed.
app= app[,c(-10,-11,-12,-13)]

#Changing the attribute
app$Reviews<-as.numeric(app$Reviews)
app$Category= as.factor(app$Category)
#Defines the various attributes of the coloumns.
str(app)

#Changing the name
dataset<-app
playstore<-app
setdat<-app


#Viewing of the dataset after the cleaning and preprocessing.
View(dataset)
#Importing the preprocessed and cleaned CSV file.
write.csv(dataset, "C:\\Users\\13128\\Desktop\\google-play-store-apps\\final output.csv")


#Building linear regression model.
# our multiple linear model
multiple<- lm(Rating~ Category+Type+Size+Price+Reviews+Installs+Content.Rating, data= dataset)
summary(multiple)


multiple2<- lm(Rating~ Category+Type+Size+Price+Reviews, data= dataset)
summary(multiple2)

#Performing stepwise regression
ols_step_all_possible(multiple2, details= TRUE)

#Performing stepwise forward regression
ols_step_forward_p(multiple2, details= TRUE)


#Performing stepwise backward regression
ols_step_backward_p(multiple, details= TRUE)


##Performing stepwise both direction regression
ols_step_both_p(multiple2, details= TRUE)

#Performing stepwise forward AIC regression
ols_step_forward_aic(multiple2, details= TRUE)

#Performing stepwise backward AIC regression
ols_step_backward_aic(multiple2, details= TRUE)

#Building Anova model
anova=lm(dataset$Rating~dataset$Category)
summary(anova)

#Plotting the box plot for ANOVA model
boxplot((dataset$Rating~dataset$Category),col=c("cyan", "light cyan", "dark turquoise"))


#Define train control for N fold cross validation
train_control <- trainControl(method="cv", number=10)

# Linear model in N fold cross validation to find predictions
model <- train(Rating~Category+Price+Size+Type+Reviews,data=dataset, trControl=train_control, method="lm",na.action=na.pass)
summary(model)
model

#Picking the columns and converting into numeric for better prediction of model.
data2<-dataset %>% dplyr::select(c(Category,Rating,Price,Size,Content.Rating, Installs,Reviews))
indx<-sapply(data2,is.factor)
data2[indx]<-lapply(data2[indx],function(x) as.numeric(x))


#Final N-Fold Cross validation model
set.seed(100)
model_Final <- train(Rating~Category+Price+Size,data=data2, trControl=train_control, method="lm",na.action=na.pass)
summary(model_Final)
model_Final


#____________________________________User Interface Code_______________________________
cf<-data.frame(Category=unique(app$Category),value=1:33)
pf<-data.frame(Price=unique(dataset$Price),value=1:92)
sf<-data.frame(Size=unique(dataset$Size),value=1:420)

header <- dashboardHeader(title = "google play store analysier") 
sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("HOME", tabName = "dashboard", icon = icon("home",class="fas fa-home")),
    menuItem("DATATABLE", tabName = "data", icon = icon("search",class="fas fa-search")),
    menuItem("BAR REPERSENTATION", tabName = "dar", icon = icon("chart-bar",class="fas fa-chart-bar")),
    menuItem("POINT REPRESENTATION", tabName = "his", icon = icon("chart-bar",class="fas fa-chart-bar")),
    #add accuracy... 
    menuItem("APP RATING PREDICTOR",tabName = "Rating", icon = icon("award",class="fas fa-award")),
    #add information...
    menuItem("ABOUT US ", tabName = "Aboutus", icon = icon("user",class="fas fa-user"))
  )
)
frow1 <- fluidRow(
  valueBoxOutput("value1"),
  valueBoxOutput("value2"),
  valueBoxOutput("value3")
)
frow2 <- fluidRow( 
  
  box(
    title = "App Rating  V/S  Apps Reviews ",
    status = "primary",
    solidHeader = TRUE ,
    collapsible = TRUE ,
    plotOutput("q2", height = "500px")
  ),
  box(
    title = "Number Of Apps By Top 15 Categories",
    status = "primary",
    solidHeader = TRUE ,
    collapsible = TRUE ,
    plotOutput("p1", height = "500px")
  )
)
body <- dashboardBody(
  tabItems(
    tabItem(tabName = "dashboard",frow1, frow2),
    
    tabItem(tabName = "dar",
            titlePanel("Creating The Plots"),
            sidebarLayout(sidebarPanel(
              selectInput(
                inputId = "characterstic",
                label="Select The Category for which you want to histogram For Top 10 Content.Rating",
                choices =sort(unique(dataset$Category)),
                selected = "ART_AND_DESIGN")), 
              mainPanel(plotOutput("ploty1"))),
            sidebarLayout(sidebarPanel(
              selectInput(
                inputId = "TI1",
                label="select the characterstic for which you want to summary",
                choices = c("Rating","Reviews","Size"),
                selected = "Rating"
              )
            ),
            mainPanel(tabsetPanel(
              tabPanel("summary",verbatimTextOutput("summary1")),
              tabPanel("Histplot",plotOutput("ploty11")),
              tabPanel("BarPlot",plotOutput("ploty12"))
            ))
            )
    ),
    
    tabItem(tabName = "data",
            titlePanel("Data Table Of Play Store Data Set"),
            sidebarPanel(selectInput(inputId="SI1",label="Category",choices=c("All",sort(as.character(factor(unique(playstore$Category))))),
                                     selected = "All")),
            sidebarPanel(selectInput(inputId="SI2",label="Price",choices=c("All",sort(as.numeric(factor(unique(playstore$Price))))),
                                     selected = "All")),
            sidebarPanel(selectInput(inputId="SI3",label="Rating",choices=c("All",sort(as.character(factor(unique(playstore$Rating))))),
                                     selected = "All")),
            mainPanel(
              tabsetPanel(
                tabPanel("Data Table",DT::dataTableOutput("m1"))
              ))),
    tabItem(tabName = "his",
            fluidPage(pageWithSidebar(
              
              headerPanel("App Graph  Explorer"),
              
              sidebarPanel(
                
                sliderInput('sampleSize', 'Sample Size', min=1, max=nrow(setdat),
                            value=min(1000, nrow(setdat)), step=500, round=0),
                
                selectInput('x', 'X', names(setdat)),
                selectInput('y', 'Y', names(setdat), names(setdat)[[2]]),
                selectInput('color', 'Color', c('None', names(setdat))),
                
                checkboxInput('jitter', 'Jitter'),
                checkboxInput('smooth', 'Smooth'),
                
                selectInput('facet_row', 'Facet Row', c(None='.', names(setdat))),
                selectInput('facet_col', 'Facet Column', c(None='.', names(setdat)))
              ),
              
              mainPanel(
                plotOutput('plot')
              )
            ))),
    
    tabItem(tabName = "Aboutus",
            titlePanel("About Devloper :"),
            infoBoxOutput("id1"),
            infoBoxOutput("id2")),
    
    tabItem(tabName ="Rating",
            titlePanel("Rating Of Your App"),
            sidebarPanel(selectInput(inputId="II1",label="Category",choices=seq(1,34),
                                     selected=2)),
            sidebarPanel(selectInput(inputId="II2",label="Price",choices=seq(1,92),
                                     selected=2)),
            sidebarPanel(selectInput(inputId="II3",label="Size",choices=seq(1,421),
                                     selected=1)),
            infoBoxOutput("r1"),
            mainPanel(
              tabsetPanel(
                tabPanel("Category Table ",DT::dataTableOutput("n1")),
                tabPanel("Price Table",DT::dataTableOutput("n2")),
                tabPanel("Size Table",DT::dataTableOutput("n3"))
              )
            )
    )
  ))
ui<-dashboardPage(title = 'Play Store App Analysiser', 
                  header, sidebar, body, skin='yellow')

server <- function(input, output) { 
  output$value1 <- renderValueBox({
    valueBox(formatC(nrow(app), big.mark=',')
             ,paste('Total Apps On DataSet',"Average Rating:",round(sum(app$Rating)/nrow(app),3)),
             icon = icon("android",class="fab fa-android"),
             color = "blue")  
  })
  
  output$n1<-DT::renderDataTable({cf})
  output$n2<-DT::renderDataTable({pf})
  output$n3<-DT::renderDataTable({sf})  
  
  output$r1<-renderInfoBox({
    
    infoBox("Rating Of Your App",
            round(predict(model_Final,data.frame(Category=as.integer(input$II1),
                                                 Price=as.integer(input$II2),Size=as.integer(input$II3)))-(as.integer(input$II1))/100,4),
            icon = icon("thumbs-up", lib = "glyphicon"),
            color = "yellow", fill = TRUE
    )
  })
  
  output$id1<-renderInfoBox({
    infoBox("Shivani Agrawal",
            "A20443602 ", "sagrawal3@hawk.iit.edu",
            #href = "--link--",
            icon = icon("user-graduate",class="fas fa-user-graduate"),
            color = "purple", fill = TRUE
    )
  })
  output$id2<-renderInfoBox({
    infoBox("Sarthak Agrawal",
            "A20444355","sagrawal4@hawk.iit.edu",
            #href = "--link--",
            icon = icon("user-graduate",class="fas fa-user-graduate"),
            color = "black", fill = TRUE
    )
  })
  
  app1<-app %>% filter(Installs=="500000000")
  app2<-app1 %>% arrange(desc(Rating)) %>% head(1)
  
  output$value2 <- renderValueBox({
    valueBox(paste(app2$Rating),
             paste('Top App:',app2$App,'Total User:',app2$Installs),
             icon = icon("download",lib='glyphicon'),
             color = "purple")  
  })
  
  x<-app %>% group_by(Category) %>% summarise(maximum=n()) %>% arrange(desc(maximum))
  top.category <- app %>% group_by(Category) %>% summarise(value = sum(as.numeric(Installs))) %>% filter(value == max(value))
  output$value3 <- renderValueBox({
    valueBox(
      paste(nrow(x)),
      paste("Total Categories Apps      ","   Top Category:",top.category$Category),
      icon = icon("gamepad",class="fas fa-gamepad"),
      color = "yellow")   
  })
  
  
  output$q2 <- renderPlot({
    ggplot(dataset, aes(x=Reviews, y=Rating)) +
      scale_x_continuous(trans='log10', labels=comma) +
      geom_point(aes(col=Type)) +
      labs(title="Android App Ratings vs Number of Reviews", subtitle="Playstore Dataset", y="Rating from 1 to 5 stars", x="Number of Reviews") +
      theme_linedraw()
  })
  
  output$p1 <- renderPlot({
    c <- app %>%group_by(Category) %>%summarize(Count = n()) %>%arrange(desc(Count))
    c <- head(c, 15)
    ggplot(c, aes(x = Category, y = Count,fill = Category)) +
      geom_bar(stat="identity", width=0.7) +ylab("Total Apps") + 
      xlab("Categories Of App") +
      theme(axis.text.x=element_blank(),
            axis.ticks.x=element_blank())+ggtitle("Top15 Categories ")
    
  })
  output$p2 <- renderPlot({
    app %>% group_by(Category) %>% summarize(totalInstalls = sum(Installs)) %>%
      arrange(desc(totalInstalls)) %>% head(15) %>%
      ggplot(aes(x = Category, y = totalInstalls, fill = Category)) +
      geom_bar(stat="identity") +ylab("Total Apps") + 
      xlab("Categories Of App") +
      labs(title= "Top15 Installed Categories" ) +
      theme(axis.text.x=element_blank(),
            axis.ticks.x=element_blank())
  })
  
  
  #barplot representation changing to box plot  
  output$plot <- renderPlot({
    setdat <- reactive({
      app[sample(nrow(app), input$sampleSize),]
    })
    
    p <- ggplot(setdat(), aes_string(x=input$x, y=input$y)) + 
      geom_boxplot(color="black", fill="orange", alpha=0.2)
    # p <- ggplot(setdat(), aes_string(x=input$x, y=input$y)) + geom_point()
    
    facets <- paste(input$facet_row, '~', input$facet_col)
    if (facets != '. ~ .')
      p <- p + facet_grid(facets)
    
    if (input$jitter)
      p <- p + geom_jitter()
    if (input$smooth)
      p <- p + geom_smooth()
    
    print(p)
    
  }, height=700)
  
  
  #changing the histogram..
  output$ploty1=renderPlot({
    dataset %>%
      filter(Category ==input$characterstic) %>%
      group_by(Content.Rating) %>%
      summarise(Count = n()) %>%
      arrange(desc(Count)) %>%
      head(10) %>%
      ggplot(aes(x = Content.Rating, y = Count)) +
      geom_bar(stat="identity", width=.5,  fill="gold1")+
      labs(title= paste("TOP10 ContentRating OF",input$characterstic,"CATEGORY" ))
  })
  
  
  output$summary1=renderPrint(
    {
      summary(dataset[,input$TI1])
    }
  )
  
  output$ploty11=renderPlot({
    hist(dataset[,input$TI1],main="Hist Plot",xlab=input$TI1)
  })
  
  output$ploty12=renderPlot({
    barplot(dataset[,input$TI1],main="bar plot",xlab=input$TI1)
  })
  
  output$m1<-DT::renderDataTable({
    if(input$SI1=="All" & input$SI2=="All" & input$SI3=="All"){
      playstore
    }else if(input$SI1!="All" & input$SI2=="All" & input$SI3=="All"){
      filter(playstore,playstore$Category==input$SI1)
    }else if(input$SI1=="All" & input$SI2!="All" & input$SI3=="All"){
      filter(playstore,playstore$Size==input$SI2)
    }else if(input$SI1=="All" & input$SI2=="All" & input$SI3!="All"){
      filter(playstore,playstore$Rating==input$SI3)
    }else if(input$SI1!="All" & input$SI2!="All" & input$SI3=="All"){
      data1<-filter(playstore,playstore$Category==input$SI1)
      filter(data1,data1$Size==input$SI2)
    }else if(input$SI1=="All" & input$SI2!="All" & input$SI3!="All"){
      data1<-filter(playstore,playstore$Price==input$SI2)
      filter(data1,data1$Rating==input$SI3)
    }else if(input$SI1!="All" & input$SI2=="All" & input$SI3!="All"){
      data1<-filter(playstore,playstore$Category==input$SI1)
      filter(data1,data1$Rating==input$SI3)
    }else{
      data1<-filter(playstore,playstore$Category==input$SI1)
      data2<-filter(data1,data1$Rating==input$SI3)
      filter(data2,data2$Size==input$SI2)
    }
  })
}
shinyApp(ui, server)



