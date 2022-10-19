# ==================================================== #
# Date
# 處理兩種日期類型:
#    1. Date: 以天為單位
#    2. DateTime: 以毫秒為單位
# ==================================================== #
using Dates

Date(1991)
Date(1991, 8, 1)

DateTime(1991, 8, 1, 19) # 到小時要用DateTime
DateTime(1991, 8, 1, 19, 30)

# 序列化
Date("19910801", "yyyymmdd")
# 也可以先做一個format
fmt = "yyyymmdd"
Date("19910801", fmt)
# !! 如果要處理"大量"，先把fmt弄成DateFormat，會快很多 !!
Date("19910801", DateFormat(fmt))
# sugar
Date("19910801", dateformat"yyyymmdd") # 這時候要用小寫喔!


dt = DateTime("1991-08-01 12:01", dateformat"yyyy-mm-dd HH:MM")
year(dt)
month(dt)
day(dt)
hour(dt)
# 以下是方便但是以後我一定會忘記
yearmonth(dt)
yearmonthday(dt)
# 星期別
dayofweek(dt)
dayname(dt)
dayofweekofmonth(dt) # 第幾個星期別??
# 在第幾季
Quarter(dt)

# 時間轉換
utlNow = DateTime(now()) - DateTime(2022, 8, 1, 20, 59)
utlNow.value / 60_000
# 以下會方便很多
round(utlNow, Minute)
floor(utlNow, Minute)
round(utlNow, Day)

# ............................................................. #
# 日期操作
# julia 的 Dates 會自動的對閏年, 30/31天的月份做調整
# ............................................................. #
dt + Day(30)
dt + Month(1)

# ............................................................. #
# 日期區間
# 這個真的滿厲害的
# ............................................................. #
Date("2022-01-01"):Day(1):Date("2022-08-01")
Date("2022-01-01"):Date("2022-08-01") # 中間沒放會報錯 (因為Range(:)預設step是Int 1)
# 可以做到這種神奇的操作
for d = Date("2022-01-01"):Week(1):Date("2022-02-01")
    println(d, " Weekday:$(dayofweek(d))")
end
# 如果變成array，就有無限可能
dates = collect(Date("2022-01-01"):Week(1):Date("2022-02-01"))
dates .+ Day(1)

# ==================================================== #
# Random
# 很多很重要
# 這邊只舉rand, randn, seed!為例
# (如果要產生特定分配，用Distribution.jl)
# ==================================================== #
using Random: seed!
rand() # uniform(0, 1)
rand(1, 10) # u(0, 1)產生1x10
rand(1.:.01:10., 10) # 給定範圍
rand(["julia", "hello", "world"]) # 可以給array
# 也可以從array中隨機抽 (看來是會先變成Vector再抽)
a = [i*j*k for i = 1:9, j = 1:9, k = 1:9]
typeof(a)
rand(a, 1)
