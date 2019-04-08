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
sti_daily_3 <- mutate(sti_daily_2, VolPercentile = (pnorm(sti_daily_2$`Volume/M`,mean(sti_daily_2$`Volume/M`), sd = sd(sti_daily_2$`Volume/M`)))*100)

#breakdown final dataset into different columns. Price under var. prices, % change under per_price_change, etc.
price <- sti_daily_2$Price
per_price_change <- sti_daily_2$`Change/%`
vol <- sti_daily_2$`Volume/M`
price_range <- sti_daily_2$`Range`

#compare prices for each day and the two days before them
price_n <- price[1:1775]
price_minus_one <- price[2:1776]
price_minus_two <- price[3:1777]
per_price_change_n <- per_price_change[1:1775]
per_price_change_n1 <- per_price_change[2:1776]
vol_minus_one <- vol[2:1776]

#modelling the ST index with the autoregressive model
# 1. plot price over time with mean
ggplot(sti_daily_3, aes(x = Date, y = Price)) + geom_line() + ggtitle("Straits Times Index, 2012 - 2019") + theme(plot.title = element_text(hjust = 0.5)) + geom_hline(yintercept=mean(sti_daily_3$Price), linetype="dashed", color = "red")
ggplot(sti_daily_3, aes(x = Date, y = `Change/%`)) + geom_line() + ggtitle("Straits Times Index, 2012 - 2019") + theme(plot.title = element_text(hjust = 0.5)) + geom_hline(yintercept=mean(sti_daily_3$`Change/%`), linetype="dashed", color = "red") + labs(x = 'Time', y = 'Daily Price Change/%')
# 2. convert to timeseries
xts_price <- xts(sti_daily_3$Price, sti_daily_3$Date)
ts_per_change <- xts(sti_daily_3$`Change/%`, sti_daily_3$Date)
# 3. find autocorrelations of price and its differences in %
acf(xts_price, lag.max = 300, plot = TRUE, main = "Autocorrelations for ST Index Price")
acf(per_price_change_n, lag.max = 300, plot = TRUE, main = "Autocorrelations for ST Index Daily Price % Change")
# 4. fit the daily price change and price to the autoregressive model
AR_fit <- arima(xts_price, order = c(1,0,0))
print(AR_fit)
change_AR_fit <- arima(x = ts_per_change, order = c(1, 0, 0))
print(change_AR_fit)
#AR model prediction for the next 50 days
ts.plot(xts_price, gpars=list(xlab="Time/Days", ylab="Price"), xlim = c(1500, 1980))
AR_forecast <- predict(AR_fit, n.ahead = 50)$pred
AR_forecast_se <- predict(AR_fit, n.ahead = 50)$se
points(AR_forecast, type = "l", col = 2)
points(AR_forecast - 2*AR_forecast_se, type = "l", col = 2, lty = 2)
points(AR_forecast + 2*AR_forecast_se, type = "l", col = 2, lty = 2)