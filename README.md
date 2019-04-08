# Various ST Index Statistics

Source file 'SG30.csv' was last updated on 29th March 2019.
### Table of Contents

* [Disclaimer](https://github.com/kingdomkitten/STindex-statistics/blob/master/README.md#disclaimer)
* [Intro](https://github.com/kingdomkitten/STindex-statistics/blob/master/README.md#intro)
* [Discussion](https://github.com/kingdomkitten/STindex-statistics/blob/master/README.md#discussion)
  * Volume Correlations
  * Autoregression Model and Prediction
## Disclaimer
All data used in this compilation of findings as of now are from 2012 to 2019. This is not completely representative of the entire historical dataset for the index. In addition, some of the graphs here examine specific conditions on their own within the stock market and for now a specific index, when really, many factors that will disrupt/contribute to price movement must be considered. The creator is also no expert in the modelling used and the interpretation of the statistics produced. Think it through carefully if you intend to use the data for legitimate purposes.  

## Intro
This project was started with the intention of exploring ideas floated around that the author has seen regarding the stock market, such as high volume determining price direction, the strength of popular technical indicators such as Relative Strength Index or P/E ratio, and the market being a random walk. Daily price data on the index was taken from Yahoo! Finance, and some extrapolations were made from the original table in the code, such as the Price Range and Volume Percentile column to provide more information to play around with. I plan to add more indices and topics in the future.

## Discussion
### Volume Related Correlations
#### 1. Histograms for Price Change/%, Range and Volume

![Histograms](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Histogram01.png)
![Histograms](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Histogram02.png)
![Histograms](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Histogram03.png)

a)  All three variables seem to follow a normal distribution. It is highly likely that any price changes and price range will be capped within this range, so it is possible to use this to evaluate entry points for the index on a daily basis. E.g. selling if price increase in a day is above the 95th percentile

#### 2. Effect of Volume on Daily Price Range

![Range](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Vol01.png)
![Range](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Vol02.png)

a)	With more buyers and sellers moving the market, volatility increases as expected. **Moderate correlation of 0.3506654 overall** for the two variables.

b)	Interestingly, **high volume is more correlated with negative days than positive ones, with correlations of 0.3802853 and 0.3238115 respectively**. Negative days are likely to induce more panic and cause more volume.

c)	As a lagging indicator (by the time all volume has been recorded, the day is over) it does not have much use in defining entry points. A possible method to utilize this information would be to place positions that profit from an increase in volatility under conditions where volume and price range diverge, with the assumption that they will re-coordinate within the remainder of the day e.g. volume has already hit a certain amount intraday, yet price range remains smaller than expected

d)	**Comparing volume percentile instead of raw volume itself gives a marginally higher correlation of 0.3585859**. Using volume percentile instead of raw volume for future analysis might give better results.

#### 3.	Effect of volume on price changes the next day

a)	There are theories that high volume green days will result in a positive price increase in the next day due to high volume indicating a large amount of buyers and large players ‘agreeing’ on a consensus direction, and the same for high volume red days.

![Movement](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Vol03.png)
![Movement](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Vol04.png)

b)	However, this does not seem to be the case for the ST index. **Observations above between 2012 and 2019 show correlations of -0.00984 and -0.00278 between the volume of a green day and price change the next day, and the volume of a red day and price change the next day respectively**. (no correlation)

![Movement](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Vol05.png)
![Movement](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Vol06.png)

c)	Although there is no correlation visible between the volume of the previous day and the degree to which it follows the same direction the next, **there is a weak correlation between the high of day N with the volume of green day N – 1, and the low of day N with the volume of red day N – 1, of 0.0467 and -0.0689 respectively**.

d)	Some of the observations for highest points are negative and some for lowest points are positive, due to gap up or gap down days where the index opens at a significantly higher or lower price than its close the previous day. If this gap is not closed within the trading day itself, the highs and lows can become negative and positive against expectations. What happens if observations where the gap is not closed are removed is shown below.

![Movement](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Vol07.png)

e)	**Correlation for green days jumps to 0.1178**. Although it is still weak, it is a significant jump from 0.0467. As long as a gap down is closed within the trading day, the correlation becomes more reliable.

![Movement](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Vol08.png)
![Movement](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/Vol09.png)

f)	All observations were arranged according to the % change of the highest point and lowest points in descending and ascending order respectively, and **5% of extreme values at each end removed**. The two graphs above show the correlation values for every number of observation values taken. **The point where gap downs and gap ups start to happen lie around the 700th observation. Introducing gap down/gap up values seem to decrease correlation drastically**.

### Examining the Index Using Autoregressive Model
From what I know, the autoregressive model follows the equation **Today's Result = Constant + (Slope x Yesterday's Result) + Noise** and the mean centered version follows **Today's Result - Mean = Slope x (Yesterday - Mean) + Noise**.

When slope is near 1, the model has high persistence (strong trend).

If **mean = 0 and slope = 1, then Today = Yesterday + Noise**, which is a random walk process.

If **slope = 0 then Today = Yesterday + Noise**, which is white noise.

Larger slope values lead to greater autocorrelation, where a time series is more dependent on its past values (resulting in more trend) and negative slopes lead to oscillation.

![Price Chart](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/AR01.png)
![Price Change Chart](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/AR02.png)

a) Above is a quick view of the index prices and price changes. ST Index price itself shows short term trend persistence. However, it seems to have been oscillating around its mean at 3150 (shown by the red line) for the past seven years. There is no clear trend or pattern in its daily percentage difference, looking similar to a white noise model.

![ACF](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/AR03.png)
![ACF](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/AR04.png)

b) The price of ST Index is highly dependent on its past with autocorrelation decaying over a few hundred observations, which means that we can expect strong persistence in any price movement, whereas its differences have no autocorrelation.

c) In fact, modelling price and the price changes in percentage to the autoregressive model using arima() respectively gives us: 
Coefficients for price:
         ar1  intercept
      0.9946  3150.5302
s.e.  0.0023    88.2417

sigma^2 estimated as 484.4:  log likelihood = -8017.26,  aic = 16040.53

Coefficients for price changes:
         ar1  intercept
      0.0315     0.0069
s.e.  0.0237     0.0175

sigma^2 estimated as 0.5106:  log likelihood = -1924.27,  aic = 3854.54

The slope of the price is close to 1 (0.9946) and the slope of percentage returns are close to 0 (0.0315). The index seems to be similar to a random walk model with white noise percentage returns, meaning that short run changes in the index, like in a random walk, should be unpredictable.

#### Using the AR predict function in R
Attempted to predict the future prices for the next 50 days using the AR model out of curiosity:

![Prediction](https://raw.githubusercontent.com/kingdomkitten/STindex-statistics/master/gallery/AR05.png)

The dotted lines represent 95% prediction intervals, stretching from a range of roughly 80 points to 520 points over the course of 50 days. A possible use of this information would be to buy or sell with a lower risk when price hits the edge of this confidence range, with the expectation that it will fall back within the range.
