using DataFrames
using CSV
using StringEncodings # 如果要用到encoding轉換，的確稍微麻煩一點
using XLSX
using Dates
using CategoricalArrays # 對應pd.Categorical
using Chain
using Statistics

begin
    # 用local可以避免產生一大堆不必要的var
    # 當然，更好的做法是用func
    local name = ["Kevin", "David", "Bob"]
    local age = [20, 34, 29]
    local height = [180, 175, 179]
    df = DataFrame(:姓名 => name, :age => age, :height => height)
    #df = DataFrame(name = name, age = age)
    #df = DataFrame(; name, age)
    path = "./temp/DF_save_example.csv"
    CSV.write(path, df, delim = "|")
end
# 如果要存不同的encoding (需要using StringEncodings)
# open(path, enc"BIG-5", "w") do f
#     CSV.write(f, df, delim = "|")
# end

# load:
CSV.read(path, DataFrame)　#　CSV.read(path, 指定格式)
DataFrame(CSV.File(path) # 比較低階的
# muti-index col的
CSV.read(path, DataFrame; header = [1, 2])
DataFrame(CSV.File(path; header = [1, 2]))
# 跳過幾行
CSV.read(path, DataFrame; header = 1, skipto = 3) # 記得: 第一行是columns name，如果跳過第一行就是沒有columns的意思
# used columns，這個很實用
CSV.read(path, DataFrame; select = [:姓名])
# limit rows
CSV.read(path, DataFrame; limit = 1)
# types
CSV.read(path, DataFrame; types = String)
# by col指定type，這個很實用
CSV.read(path, DataFrame; types = Dict(:age => String, :height => Float64))

# date format
data = """
code,date
0,2019/01~01
1,2019/01~02
"""
CSV.read(IOBuffer(data), DataFrame; dateformat="yyyy/mm~dd")
#

# ================================================================== #
# EXCEL
# ================================================================== #

# 寫入xlsx
function write_xlsx(name, df)
    path = "./temp/$name.xlsx"
    data = eachcol(df)
    cols = names(df)
    XLSX.writetable(path, data, cols)
end
write_xlsx("DF_save_example", df)

# load: 滿麻煩的: readxlsx讀進來是一個XLSXFile |> 先eachtablerow(對，存的時候是col，讀的時候是row) |> 轉成DataFrame
XLSX.eachtablerow(XLSX.readxlsx("./temp/DF_save_example.xlsx")["Sheet1"]) |> DataFrame

# ====================================================================== #
# DataFrame:
# ====================================================================== #
# index
# 用"."來indexing columns，竟然連中文也可以!??
df.姓名
df.age
# 比較正規的作法
df[!, "姓名"]
df[:, "姓名"] # 這種作法會先在內存複製此col，
df[!, "姓名"] === df[:, "姓名"] # 值相等(內存中複製)
df[!, "姓名"] === df.姓名 # 完全相等(包括記憶體)

# 用idx
df[1:2, 1]
# 依值尋找
findfirst(x->x=="Kevin", df[!, "姓名"])
# Filter
filter(:age => x->x<30, df)
filter(:age => <=(30), df) # 超酷，partial function application。用 "比較operator()"就可以減少輸入的函數
# 就像這樣
<(3, 4)
# 拆解是這樣
f(x) = x < 4
f(3)
f2 = <(4)
# 這招在filter, map, reduce時會有奇效，讓一切變得非常優雅
filter(<(5), 1:10)
findall(==(4), [1,2,3,4,5,3,1,3,4])
# Predicate Function Negation: "bool反向"
findall(x-> !isodd(x), [1, 2, 3, 4, 5, 3, 1, 3, 4])
findall(!isodd, [1, 2, 3, 4, 5, 3, 1, 3, 4])

# ........................................................ #
# subset:
# 和filter的主要差異是，對於missing的處理會更容易一點
# 注意： DataFrame在subset中是第一個參數，但在filter是第二個
#       事實上，DataFrames.jl的函數大多把df當作第一個參數除非是擴充原有func的mutilple dispatch
# !! 另外 !! subset是ByRow的
# ........................................................ #
subset(df, :age => ByRow(<(30)))

df2 = vcat(df, DataFrame(:姓名 => "Steve", :age => 30, :height => missing))
# 處理missing
filter(:height => >(175), df2) # 有missing的時候，filter就會壞掉
subset(df2, :height => ByRow(>(175)), skipmissing = true) # subset有處理missing的部分

# ........................................................ #
# 性能強大的select
# ........................................................ #
select(df2, :姓名)
select(df2, Not(:姓名))
select(df2, :height, Not(:姓名))
select(df2, :height, :)
# 可以重新命名
select(df2, :姓名 => :name, :)
select(df2, (:姓名 => :name, :age => :年齡)...) # 也可以用splat...

# ........................................................ #
# 類型與缺失值
# ........................................................ #
function wrong_types()
    id = 1:4
    date = ["28-01-2018", "03-04-2019", "01-08-2018", "22-11-2020"]
    age = ["adolescent", "adult", "infant", "adult"]
    DataFrame(; id, date, age)
end

function fix_date_col(df::DataFrame) :: DataFrame
    to_date(dates::Vector{String}) = Date.(dates, dateformat"dd-mm-yyyy", )
    df[!, :date] = df[!, :date] |> to_date
    return df
end
wrong_types() |> fix_date_col |> x->sort(x, :date, rev = false)

# 一個有趣的應用: CategoricalArrays 預設文字排序。 pandas也有，只是還沒遇到機會用
function fix_age_col(df::DataFrame) ::DataFrame
    lvs = ["infant", "adolescent", "adult"]
    df[!, :age] = categorical(df[!, :age]; levels = lvs, ordered = true)
    return df
end

begin
wrong_types() |> fix_date_col |>
                 fix_age_col |>
                 df -> sort(df, [:age, :date,], rev = [false, true])
end
# 上面的chain基本上長這樣
sort(fix_date_col(
        fix_age_col(wrong_types())
    )
    ,[:age, :date], rev = [false, true])
# Chain.jl # "_"表示上一步的output。可以用@aside做一些不會回傳到下一步的事情。
df_sort = @chain wrong_types() begin
    fix_date_col
    fix_age_col
    @aside println("size of current df: $(size(_))")
    sort(_, [:age, :date,], rev = [false, true])
end

# ............................................................ #
# join
# ............................................................ #
df_weight = DataFrame(:name => df2[1:2:4, "姓名"],
                      :weight => [70, 65])
df_basic = rename!(df2[:, :], :姓名 => :name)
# @chain df2[:, :], rename(_, :姓名 => :name)

# inner join
innerjoin(df_basic, df_weight; on = [:name])

#outerjoin
outerjoin(df_basic, df_weight; on = [:name])

#leftjoin
leftjoin(df_basic, df_weight; on = [:name])
#rightjoin
rightjoin(df_basic, df_weight; on = [:name])
# crossjoin: 不常用，就是columns的乘法。不需要on。如果有同樣名稱的col，需要makeunique = true
crossjoin(df_basic, df_weight, makeunique = true)

# semijoin: 存在於左側 & 存在於兩側 (約等於 innerjoin + leftjoin) ?: 阿不就innerjoin?
semijoin(df_basic, df_weight; on = [:name])

# antijoin: 存在於左側、不存在於右側
antijoin(df_basic, df_weight; on = [:name])

# ............................................................ #
# transform
# 邏輯: source => transformation i.e. func => target
# i.e. 來源col => 做一些事 (func) => 放去哪裡?
# ............................................................ #
function transform_test()
    leftjoined = leftjoin(df_basic, df_weight; on = [:name])
    bmi(w::Vector, h::Vector) = @. w / (h/100) ^ 2
    # transform!(leftjoined, [:weight, :height] => bmi => :BMI)
    transform!(leftjoined, [:weight, :height] => bmi => :BMI)
end
transform_test()

# 也可以用select轉換
function transform_bySelect()
    leftjoined = leftjoin(df_basic, df_weight; on = [:name])
    select(leftjoined, :, :age => (x->x.+(1)) => :age_plus1)
end
transform_bySelect()


# ............................................................ #
# groupby: 比較像R語言 split-apply-combine
# 先將data split成小組 => apply一些事情 => combine每組結果
# groupby(df, by_col) |> gdf -> combine(gdf, col => func)
# ............................................................ #

data = XLSX.readxlsx("./temp/graph_data_CA_PS.xlsx")["melt data"] |> XLSX.eachtablerow |> DataFrame

@chain data begin
    subset(_,
           :tag => ByRow(==("mean")),
           :feature => ByRow(==("prefer_BA")),
           skipmissing = true)
    groupby(_, :refer)
    combine(_, :value => mean,
               :value => median => "PR50", # 可以像這樣給新名字
               :value => (x->quantile(x, .75)) => "PR75")
end

@chain data begin
    subset(_,
           :tag => ByRow(==("mean")),
           :feature => ByRow(==("prefer_BA")),
           skipmissing = true)
    groupby(_, :refer)
    combine(_, [:value, :stats_year] .=> mean .=> [:val_avg, :year_avg]) # 可以像這樣一次處理多個col
end

@chain data begin
    subset(_,
           :tag => ByRow(==("mean")),
           :feature => ByRow(==("prefer_BA")),
           skipmissing = true)
    groupby(_, :refer)
    combine(_, [:value, :stats_year] => (v, y)->mean(v+y)) # 多輸入可以這樣，但因為很醜，還是像下面那樣好一點
end

foo(v:: Vector, y:: Vector) = mean(v + y)
@chain data begin
    subset(_,
           :tag => ByRow(==("mean")),
           :feature => ByRow(==("prefer_BA")),
           skipmissing = true)
    groupby(_, :refer)
    combine(_, [:value, :stats_year] => foo) # 多輸入可以這樣，但因為很醜，還是像下面那樣好一點
end

# 

transform(leftjoined, [:weight, :height] => bmi => :BMI)

@. leftjoined[!, :weight] / (leftjoined[!, :height] / 100) ^ 2
