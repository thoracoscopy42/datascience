#Sprawdzanie czy każda macierz zawiera określone wartości na podstawie lokalizacji

using CSV
using DataFrames
using Dates
using ScientificTypes
using Statistics

df = CSV.read("data/partial/weather/san_antonio.csv", DataFrame) #czytanie konkretnych plików - odnoszenie się do scieżek

# names(df) #nazwy kolumn
# describe(df)
unique(df.location) #sprawdzanie unikatowych elementów/ stringów, czy wszystko jest w porządku głównie, żeby sprawdzić czy np. lokalizacja sie zgadza 
