# ============================================= #
# 常用的原生資料結構
# String， Tuple， NamedTuple， UnitRange， Arrays， Pair， Dict, Symbol。
# ============================================= #

# methodswith(type): 顯示此type的methods
first(methodswith(Tuple), 5)

# boardcast
[1, 2, 3] .+ 1
f(x) = sin(x^2) + 1
f.([1, 2, 3])


# 帶"!"的func: 表示不會創造"新"副本，直接取代。
#使用時要小心。在大型資料很有用(節省記憶體)
function add_one!(v::Vector{T} where T<:Real)
    for i = 1:length(v)
        v[i] += 1
    end
    return nothing
end
function add_one!(v::Vector{T} where T<:String)
    for i = 1:length(v)
        v[i] *= "1"
    end
    return nothing
end
a = [1, 2, 3]
add_one!(a)
b = ["1", "b", "c"]
add_one!(b)
b
# --------------------------------------------- #
# 題外話: Vectory & Array
# --------------------------------------------- #
Array{Int, 1} == Vector{Int}
# 低階初始化: (最快的儲存法)
a = Vector{Int}(undef, 10)
idx = 1
for i = 1:5, j = 5:6 # sugar of nested loop
    a[idx] = i*j
    idx += 1
end
a

# --------------------------------------------- #
# 字串
# --------------------------------------------- #
text = "this is a String."
typeof(text)
# 可以這樣定義多行文字
text = "This is a String.
This is the second line.
"
# 如果用3個"會更方便，就不用julia會忽略開頭的縮行，讓對其更方便
text = """
       this is a String.
       this is the second line without tab.
       """
# interpolation(插值)
text = """
       this is a String.
       this is the second line without tab.
       list a is shown below:
        $(a)
       """
println(text)
# 可以做一些有趣的應用
function size_comparision(a::Int, b::Int)
    a > b && return "$a > $b"
    a == b && return "$a = $b"
    a < b && return "$a < $b"
end
size_comparision(1, 3)
size_comparision(3, 1)
size_comparision(3, 3)
# contains, startswith, endswith
contains(text, "without tab")
startswith(text, "Not_a_head")
endswith(text, "]\n")
# lowercase, uppercase, titlecase, lowercasefirst
lowercase(text)
uppercase(text)
titlecase(text)
lowercasefirst(uppercase(text))
# replace: 有一個新的類別: Pair "a" => "b"
replace(text, "second line" => "XXXXX")
replace(text, r"se.*e?" => "XX")
# split: 切割
split(text, " ")
collect(eachmatch(r"([a-zA-Z]+)", text))
# 字串型別轉換
a = "1"
parse(Int, a)
parse(Float64, a)
# 為了更安全的轉換型別:
b = "abc"
parse(Int, b)
tryparse(Int, b) # 如果try失敗，return nothing

# ------------------------------------------------- #
# Tuple: 可以含不同type的容器，immutable
# 如果func回傳多個值，那個return就是一個tuple
# ------------------------------------------------- #
my_tuple = (1, 2, "abc")
my_tuple[3]
# 當要傳遞多個args給匿名函式時，也要用tuple
map((x, y) -> x + y, 2, 3)
map((x, y) -> x + y, [1, 2, 3], [4, 5, 6])
((x, y) -> x + y).([1,2,3], [4,5,6])
# NamedTuple
my_namedTuple = (i = 1, pi = 3.14, s = "circle1")
my_namedTuple.pi
# NamedTuple的快捷語法: func中namedArg的應用: ";" (註: func(locational args ; named args) )
i, a, s = 1, 3.14, "circle2"
my_namedTuple_quick = (; i, a, s) # ";"後的東西當作named arg，有點像py中的f-string的=

# ------------------------------------------------- #
# 數組: Vector, Matrix, Array
# ------------------------------------------------- #

# 低階高性能的創造數組:
# 默認構造器(undef): 將{}中的型別傳到構造器中，並用
# undef = array initializer with undefined values
# 建構一個len = 10的array
my_vec = Vector{Int}(undef, 10)
my_mat = Matrix{Int}(undef, 10, 5)

# 快速預設建立
zeros(10)
ones(10, 5)
# 0和1之外的其他值的建立: 先建立 |> fill!
my_mat_2 = Matrix{Int}(undef, 10, 5)
fill!(my_mat_2, 1)
# ................................................... #
# 也可以用比較土炮的做法
# 不強健，我覺得知道有這種方法就好。
# 其他使用者不小心把空白->換行就GG了
# ................................................... #
a = [[1 2]
     [3 4]] # 2×2 Matrix{Int64}
a[:, 1]
# 這個方法不是很好，因為
[[1 2] [3 4]] # 1×4 Matrix{Int64} --> 用空白和用換行的結果會不一樣

# 這個做法比較匪夷所思，例如中間加一個","就會變成Array(Matrix{T, 1, 2})
a = [[1 2], [3, 4]]
# 簡單的說，" "隔開就會變成matrix: (註: julia是columns-major order, 意即由上而下)
a = [[1,2,3] [4,5,6]]
# 好，這個方法可以宣告型別
Float64[[1 2] [3 4]]
Bool[0, 1, 0]
# 雖然這個方法不是很好，但用在簡單的合併還是可以一用
#(但我覺得還是不夠強健，如果其他使用者不小心換行了就GG了)
[ones(5) zeros(5)]

# ................................................... #
# comprehension
# ................................................... #
Float64[i for i in 1:5 if isodd(i)] # 可以指定型別
hcat(1:5, 6:10) # 比起前段提到的" "，這個方法可靠的多
cat(1:5, 6:10, dims = 1) # hact & vcat的標準做法
cat(1:5, 6:10, dims = 2)

# ................................................... #
# array檢查
# 例如型別...
# ................................................... #
# 型別
eltype([1, 1, 1])
eltype([1, 2., "A"])
typeof.([1, 2., "A"])
# 長度 & 維度
length([1, 2, 3])
ndims([[1, 2, 3], [4, 5, 6]])
size(Matrix{Int}(undef, 10, 2))
# reshape
reshape(ones(10, 2), (:, 1))
# 最有效率的變成單維度(vector)
reshape(ones(10, 2), (:, 1)) |> vec
reshape(ones(10, 2), (:, )) # 不要加第二個idx 就會變vector

# ................................................... #
# 矩陣運算
# ................................................... #
a = ones(3, 2)
b = [2, 4]
a * b # 就是numpy的np.dot
# element wise的運算要注意shape
a .* reshape(b, 1, 2)
a .- reshape(b, 1, 2)

# ................................................... #
# slice
# 和py差不多，比較不同的是沒有-1 ("end" in jl)，多加一個開頭"begin"
# ................................................... #
a = [i*j for i = 1:9, j = 1:9] # 99乘法表
# 單點
a[5, 5]
# 切片
a[5, :]
a[:, 5]
# Xs, Ys
a[[1, 3], [8, 9]]
# Xs, Y-slice
a[[1, 3], 8:9]

# Q? 這兩個方法會有不同的結果
[i*j for i = 1:9 for j = 1:9] # Vector
[(i, j) for i = 1:9, j = 11:19] # Matrix

# ................................................... #
# 操作
# ................................................... #
# 賦值
a = ones(3, 2)
a[2, 2] = 5
# element wise
a .+ 1
# 以下由強健到鬆散
map(x->sin(x), a)
sin.(a)
(x->sin(x)).(a)
# apply by axis
# note: dims = 1 表示 f(a[:, 1]), f(a[:, 2]), ...
mapslices(x->sum(x), a, dims = 1)
mapslices(x->sum(x), a, dims = 2)

# ................................................... #
# 迭代
# ................................................... #
a = [ i^j for i = 1:9, j = 1:9]
a
for i = a # 如果直接iter，是從dims = 1開始 (default = 類似eachcol)
    println(i)
end
for i = eachcol(a)
    println(i)
end
for i = eachrow(a)
    println(i)
end

# ----------------------------------------------------------- #
# Pair
# 簡單的說就是 "包含兩個元素的數據結構(不過隱含著指向的意味)"
# 這兩個元素儲存在".first" & ".second"中 (也可以用"last(pair)"代替.second)
# 被大量應用在 DataFrame.jl 和 作圖 中
# ----------------------------------------------------------- #
my_pair = "julia" => 42
my_pair.first, my_pair.second
first(my_pair), last(my_pair)

# ----------------------------------------------------------- #
# Dict
# 其實就是Pair組成的
# ----------------------------------------------------------- #
a = Dict{String, Int64}()
a["a"] = 1
a["b"] = 2


# ----------------------------------------------------------- #
# Symbol
# 不是資料結構，是一種型別 (就像String)
# 用處? 比起"s"，:s 少打一點符號。
# DataFrame.jl大量地使用
# ----------------------------------------------------------- #
# Symbol 可以和 String 快樂的互相轉換
String(:my_symbol)
Symbol("my_symbol")

# ----------------------------------------------------------- #
# Splat: 展開運算子
# 就是"..."
# 用於func調用時，轉換args序列

# 任何时候，若 Julia 在函数调用中发现了展开运算符，那么它会将运算符前的集合转化为一组逗号分隔的参数序列。
# ----------------------------------------------------------- #
function sum_three_elements(x:: T, y:: T, z:: T) where T <: Real
    x + y + z
end
a = [1, 2, 3]
sum_three_elements(a...)
sum_three_elements(1:2:5...)
