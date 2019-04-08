library(dplyr)
library(ggplot2)
library(stringr)
library(zoo)

#import Straits Times Index daily data
sti_daily <- read.csv('SG30.csv', stringsAsFactors = FALSE)

#modify column names
col_names <- c('Date', 'Price', 'Open', 'High', 'Low', 'Volume/M','Change/%')
colnames(sti_daily) <- col_names

#modify table data types accordingly
sti_daily$Date <- as.Date(sti_daily$Date, format = "%b %d, %Y")
sti_daily$Price <- as.numeric(gsub(",","",sti_daily$Price,fixed=TRUE))
sti_daily$Open <- as.numeric(gsub(",","",sti_daily$Open,fixed=TRUE))
sti_daily$High <- as.numeric(gsub(",","",sti_daily$High,fixed=TRUE))
sti_daily$Low <- as.numeric(gsub(",","",sti_daily$Low,fixed=TRUE))
sti_daily$'Volume/M' <- str_replace(sti_daily$'Volume/M', "1.13B", "1130M")
sti_daily$`Volume/M` <- as.numeric(gsub("M","",sti_daily$'Volume/M',fixed=TRUE))
sti_daily$`Change/%` <- as.numeric(gsub("%","",sti_daily$'Change/%',fixed=TRUE))


#omitting weekends and public holidays where volume will be NA 
sti_daily_2 <- na.omit(sti_daily)

#add new column Range and Green (logical for days where index change is positive), and % values for High/Low
sti_daily_2 <- mutate(sti_daily_2, 'High Change/%' = (sti_daily_2$High - (sti_daily_2$Price / (100 + sti_daily_2$`Change/%`))*100) / ((sti_daily_2$Price / (100 + sti_daily_2$`Change/%`))*100)*100)
sti_daily_2 <- mutate(sti_daily_2, 'Low Change/%' = (sti_daily_2$Low - (sti_daily_2$Price / (100 + sti_daily_2$`Change/%`))*100) / ((sti_daily_2$Price / (100 + sti_daily_2$`Change/%`))*100)*100)

sti_daily_2 <- mutate(sti_daily_2, Range = sti_daily_2$High - sti_daily_2$Low)
sti_daily_2 <- mutate(sti_daily_2, Green = sti_daily_2$`Change/%` >= 0)


#breakdown final dataset into different columns. Price under var. prices, % change under per_price_change, etc.
price <- sti_daily_2$Price
per_price_change <- sti_daily_2$`Change/%`
vol <- sti_daily_2$`Volume/M`
price_range <- sti_daily_2$`Range`



#histograms for volume, day ranges and daily price changes in %
ggplot(sti_daily_2, aes(x = sti_daily_2$`Volume/M`)) + geom_histogram() + scale_x_log10() + ggtitle("Logarithmic Histogram of Daily Volumes 2012 - 2019") + labs(y="Frequency", x = "Volume/M")
ggplot(sti_daily_2, aes(x = sti_daily_2$'Change/%')) + geom_histogram() + ggtitle("Histogram of Daily Price % Change 2012 - 2019") + labs(y="Frequency", x = "Price Change/%")
ggplot(sti_daily_2, aes(x=sti_daily_2$Range)) + geom_histogram() + scale_x_log10() + ggtitle("Histogram of Daily Ranges 2012 - 2019") + labs(y="Frequency", x = "Price Range")

#as we can see, volume, range and daily price changes all seem to follow a normal distribution. we can estimate percentiles for daily volume to give us another statistic to play with.
sti_daily_3 <- mutate(sti_daily_2, VolPercentile = (pnorm(sti_daily_2$`Volume/M`,mean(sti_daily_2$`Volume/M`), sd = sd(sti_daily_2$`Volume/M`)))*100)

#plot volume against daily price range and view correlation
ggplot(sti_daily_3, aes(x = sti_daily_3$`Volume/M`, y = sti_daily_3$Range, color = sti_daily_3$Green)) + geom_point() + scale_x_log10() + scale_y_log10() + ggtitle("Graph of Daily Price Range against Volume/M") + labs(y="Daily Price Range", x = "Volume/M", color = "Positive Day") + theme(plot.title = element_text(hjust = 0.5))
cor(vol, price_range)
#correlation for red and green days separately
sti_daily_4 <- sti_daily_3[sti_daily_3$Green == TRUE, ]
cor(sti_daily_4$`Volume/M`, sti_daily_4$Range)

sti_daily_5 <- sti_daily_3[sti_daily_3$Green == FALSE, ]
cor(sti_daily_5$`Volume/M`, sti_daily_5$Range)


#plot volume percentile against daily price range and view correlation
ggplot(sti_daily_3, aes(x = sti_daily_3$`VolPercentile`, y = sti_daily_3$Range, color = sti_daily_3$Green)) + scale_y_log10() + geom_point()   + ggtitle("Graph of Daily Price Range against Volume/Percentile") + labs(y="Daily Price Range", x = "Volume/Percentile", color = "Positive Day") + theme(plot.title = element_text(hjust = 0.5))
cor(sti_daily_3$VolPercentile, sti_daily_3$Range)  #correlation is slightly higher

#does volume on a green day affect the price change of tomorrow?
# 1. create new dataframe with overlaying data from days N and day N-1
price_volume_comparison <- data.frame(sti_daily_3$`Change/%`[1:1776], sti_daily_3$VolPercentile[2:1777], sti_daily_3$`Volume/M`[2:1777], sti_daily_3$Green[2:1777], sti_daily_3$Green[1:1776], sti_daily_3$`High Change/%`[1:1776], sti_daily_3$`Low Change/%`[1:1776])
colnames(price_volume_comparison) <- c('Change/%', 'VolPercentile of Previous Day', 'volume of Previous Day/M', 'Price Rises the Previous Day', 'Price Rises Today', 'Highest Point Change/%', 'Lowest Point Change/%')
# 2. take all observations where day N-1 is green
green_price_volume_comparison <- price_volume_comparison[price_volume_comparison$`Price Rises the Previous Day` == TRUE, ]
# 3. find correlation value and view graph. no correlation = no way to pinpoint a specific price change value with volume.
ggplot(green_price_volume_comparison, aes(x = green_price_volume_comparison$`volume of Previous Day/M`, y = green_price_volume_comparison$`Change/%`)) + geom_point() + scale_x_log10() + ggtitle("% Change Against Volume/M") + labs(x="Volume of Previous Day/M", y = "Price Change/%")
cor(x = green_price_volume_comparison$`volume of Previous Day/M`, y = green_price_volume_comparison$`Change/%`)
# 4. can a green day today be attributed to high volume yesterday?
two_green_days <- green_price_volume_comparison$`Price Rises Today` == TRUE
# 5. rinse and repeat for the highs after green days
ggplot(green_price_volume_comparison, aes(x = green_price_volume_comparison$`volume of Previous Day/M`, y = green_price_volume_comparison$`Highest Point Change/%`)) + geom_point() + scale_x_log10() + ggtitle("Highest Point % Change Against Volume/M") + labs(x="Volume of Previous Day/M", y = "High Price Change/%")
cor(x = green_price_volume_comparison$`volume of Previous Day/M`, y = green_price_volume_comparison$`Highest Point Change/%`)
# 5a. Since there is also little correlation, what about days where all gap downs are closed, which is majority of the days i.e. High is a positive % change from the previous day
gapdownclosed <- green_price_volume_comparison[green_price_volume_comparison$`Highest Point Change/%` >= 0, ]
ggplot(gapdownclosed, aes(x = gapdownclosed$`volume of Previous Day/M`, y = gapdownclosed$`Highest Point Change/%`)) + geom_point() + scale_x_log10() + ggtitle("Highest Point % Change Against Volume/M") + labs(x="Volume of Previous Day/M", y = "High Price Change/%")
cor(x = gapdownclosed$`volume of Previous Day/M`, y = gapdownclosed$`Highest Point Change/%`)
# 5b. How does correlation change as we remove extreme observations?
#sort high percentage changes in descending order
descending_highpoints <- green_price_volume_comparison[order(-green_price_volume_comparison$`Highest Point Change/%`),]
#find the correlation for every number of observations with 5% of the observations from extreme ends removed
correlations <- c()
for (i in 1:length(descending_highpoints$`Highest Point Change/%`)){
  correlations[i] <- cor(x = descending_highpoints$`volume of Previous Day/M`[1:i], y = descending_highpoints$`Highest Point Change/%`[1:i])
}
ts_correlations <- ts(correlations)
plot(ts_correlations[45:855], main="Correlation Values against Number of Observations Considered",ylab="Correlation of Daily High Percentage Change with Previous Day Volume", xlab = "Number of Observations Taken", type="l", col="blue", log="y")



# 6. rinse and repeat for red days
red_price_volume_comparison <- price_volume_comparison[price_volume_comparison$`Price Rises the Previous Day` == FALSE, ]
ggplot(red_price_volume_comparison, aes(x = red_price_volume_comparison$`volume of Previous Day/M`, y = red_price_volume_comparison$`Change/%`)) + geom_point() + scale_x_log10() + ggtitle("% Change Against Volume for Red Days/M") + labs(x="Volume of Previous Day/M", y = "Price Change/%")
cor(x = red_price_volume_comparison$`volume of Previous Day/M`, y = red_price_volume_comparison$`Change/%`)
two_red_days <- red_price_volume_comparison$`Price Rises Today` == FALSE

# 7. rinse and repeat for the lows after red days
ggplot(red_price_volume_comparison, aes(x = red_price_volume_comparison$`volume of Previous Day/M`, y = red_price_volume_comparison$`Lowest Point Change/%`)) + geom_point() + scale_x_log10() + ggtitle("Lowest Point % Change Against Volume/M") + labs(x="Volume of Previous Day/M", y = "Low Price Change/%")
cor(x = red_price_volume_comparison$`volume of Previous Day/M`, y = red_price_volume_comparison$`Lowest Point Change/%`)
# 7a. How does correlation change as we remove extreme observations?
#sort low percentage changes in ascending order
ascending_lowpoints <- red_price_volume_comparison[order(red_price_volume_comparison$`Lowest Point Change/%`),]
#find the correlation for every number of observations with 5% of the observations from extreme ends removed
red_correlations <- c()
for (i in 1:length(ascending_lowpoints$`Lowest Point Change/%`)){
  red_correlations[i] <- cor(x = ascending_lowpoints$`volume of Previous Day/M`[1:i], y = ascending_lowpoints$`Lowest Point Change/%`[1:i])
}
ts_red_correlations <- ts(red_correlations)
plot(ts_red_correlations[45:855], main="Correlation Values against Number of Observations Considered",ylab="Correlation of Daily Most Negative Percentage Change with Previous Day Volume", xlab = "Number of Observations Taken", type="l", col="blue")

