# DataScience

## Modele regresyjne zapotrzebowania energetycznego na podstawie danych pogodowych

Projekt przedstawia analizę zależności między warunkami pogodowymi a dziennym zapotrzebowaniem na energię elektryczną w wybranych lokalizacjach w Teksasie: Austin, Dallas, Houston oraz San Antonio.

Celem projektu było przygotowanie danych pogodowych i energetycznych, połączenie ich w spójny zbiór modelowy oraz porównanie kilku modeli regresyjnych służących do predykcji dziennego zapotrzebowania energetycznego.

---

## Cel projektu

Głównym celem projektu było sprawdzenie, czy podstawowe zmienne pogodowe mogą zostać wykorzystane do przewidywania dziennego zapotrzebowania energetycznego.

W projekcie wykonano:

- preprocessing danych pogodowych,
- preprocessing danych energetycznych,
- agregację danych do poziomu dziennego,
- podział danych według lokalizacji,
- połączenie danych pogodowych i energetycznych po dacie,
- trenowanie kilku modeli regresyjnych,
- porównanie modeli za pomocą metryk MAE, RMSE oraz R²,
- wizualizację wyników,
- analizę predykcji rzeczywistych i przewidywanych wartości.

---

## Dane

W projekcie wykorzystano dwa zbiory danych:

1. dane pogodowe,
2. dane dotyczące dziennego zapotrzebowania energetycznego.

Dane pogodowe zawierają informacje o warunkach atmosferycznych dla analizowanych lokalizacji. Po preprocessingu zostały one podzielone według miast: Austin, Dallas, Houston oraz San Antonio.

Dane energetyczne zawierają dzienne wartości zapotrzebowania energetycznego dla wybranych regionów. Ponieważ dane energetyczne nie były bezpośrednio przypisane do pojedynczych miast, zastosowano mapowanie lokalizacji na odpowiadające im regiony energetyczne.

| Lokalizacja | Zmienna docelowa | Opis |
|---|---|---|
| Austin | `scent_daily` | dzienne zapotrzebowanie energetyczne dla regionu SCENT |
| San Antonio | `scent_daily` | dzienne zapotrzebowanie energetyczne dla regionu SCENT |
| Dallas | `north_daily` | dzienne zapotrzebowanie energetyczne dla regionu NORTH |
| Houston | `coast_daily` | dzienne zapotrzebowanie energetyczne dla regionu COAST |

Austin oraz San Antonio korzystają z tej samej zmiennej energetycznej `scent_daily`, ponieważ zostały przypisane do tego samego regionu energetycznego. Różnią się jednak danymi pogodowymi, dlatego zostały potraktowane jako osobne przypadki modelowe.

Dane pogodowe i energetyczne zostały połączone na podstawie kolumny `date`. Modelowanie wykonano na danych zagregowanych do poziomu dziennego.

---

## Modele

W projekcie porównano pięć podejść regresyjnych:

| Model | Opis |
|---|---|
| `MeanBaseline` | model bazowy przewidujący średnią wartość zmiennej docelowej ze zbioru treningowego |
| `LinearRegression` | klasyczna regresja liniowa |
| `RidgeRegression` | regresja liniowa z regularyzacją |
| `DecisionTree` | regresyjne drzewo decyzyjne |
| `RandomForest` | regresyjny las losowy |

Model `MeanBaseline` został wykorzystany jako punkt odniesienia. Dzięki temu można było sprawdzić, czy modele uczące się zależności między zmiennymi pogodowymi a zapotrzebowaniem energetycznym rzeczywiście poprawiają jakość predykcji względem prostego przewidywania średniej wartości.

Dane zostały podzielone na zbiór treningowy i testowy w proporcji 80/20. Wszystkie modele dla danej lokalizacji były oceniane na tym samym podziale danych, co umożliwia ich bezpośrednie porównanie.

---

## Metryki oceny

Do porównania modeli wykorzystano trzy metryki:

| Metryka | Znaczenie |
|---|---|
| `MAE` | średni bezwzględny błąd predykcji |
| `RMSE` | pierwiastek średniego błędu kwadratowego |
| `R²` | współczynnik determinacji określający dopasowanie modelu do danych |

Główną metryką wyboru najlepszego modelu było `RMSE`, ponieważ silniej karze duże błędy predykcji niż `MAE`. Wysoka wartość `R²` oznacza natomiast, że model dobrze wyjaśnia zmienność zmiennej docelowej.

---

## Wyniki modelowania

Poniższa tabela przedstawia wyniki wszystkich modeli dla analizowanych lokalizacji.

| Lokalizacja | Target | Model | MAE | RMSE | R² |
|---|---|---:|---:|---:|---:|
| Austin | `scent_daily` | Ridge Regression | 48.16 | 439.77 | 0.999862 |
| Austin | `scent_daily` | Linear Regression | 53.87 | 440.05 | 0.999862 |
| Austin | `scent_daily` | Decision Tree | 630.69 | 841.50 | 0.999496 |
| Austin | `scent_daily` | Random Forest | 1106.28 | 1763.99 | 0.997784 |
| Austin | `scent_daily` | Mean Baseline | 32114.19 | 37544.40 | -0.003659 |
| Dallas | `north_daily` | Ridge Regression | 7.64 | 68.70 | 0.999854 |
| Dallas | `north_daily` | Linear Regression | 8.89 | 68.78 | 0.999854 |
| Dallas | `north_daily` | Decision Tree | 107.18 | 145.50 | 0.999347 |
| Dallas | `north_daily` | Random Forest | 161.99 | 242.73 | 0.998182 |
| Dallas | `north_daily` | Mean Baseline | 4586.74 | 5741.84 | -0.017084 |
| Houston | `coast_daily` | Linear Regression | 130.27 | 799.05 | 0.999792 |
| Houston | `coast_daily` | Ridge Regression | 114.84 | 799.23 | 0.999792 |
| Houston | `coast_daily` | Decision Tree | 998.71 | 1495.09 | 0.999271 |
| Houston | `coast_daily` | Random Forest | 1806.16 | 3461.76 | 0.996092 |
| Houston | `coast_daily` | Mean Baseline | 48440.00 | 55628.03 | -0.009042 |
| San Antonio | `scent_daily` | Linear Regression | 59.26 | 439.41 | 0.999863 |
| San Antonio | `scent_daily` | Ridge Regression | 51.44 | 439.66 | 0.999862 |
| San Antonio | `scent_daily` | Decision Tree | 630.69 | 841.50 | 0.999496 |
| San Antonio | `scent_daily` | Random Forest | 1042.71 | 1668.91 | 0.998017 |
| San Antonio | `scent_daily` | Mean Baseline | 32114.19 | 37544.40 | -0.003659 |

---

## Najlepsze modele

Najlepszy model dla każdej lokalizacji został wybrany na podstawie najniższej wartości `RMSE`.

| Lokalizacja | Najlepszy model | RMSE | MAE | R² |
|---|---|---:|---:|---:|
| Austin | Ridge Regression | 439.77 | 48.16 | 0.999862 |
| Dallas | Ridge Regression | 68.70 | 7.64 | 0.999854 |
| Houston | Linear Regression | 799.05 | 130.27 | 0.999792 |
| San Antonio | Linear Regression | 439.41 | 59.26 | 0.999863 |

Najlepsze wyniki uzyskały modele liniowe: `LinearRegression` oraz `RidgeRegression`. Modele drzewiaste, czyli `DecisionTree` i `RandomForest`, osiągnęły gorsze rezultaty niż modele liniowe, choć nadal były znacząco lepsze od modelu bazowego.

---

## Wizualizacja wyników

Wyniki modelowania zostały przedstawione również w formie wykresów. Dla każdej lokalizacji przygotowano osobne porównanie modeli obejmujące metryki `MAE`, `RMSE` oraz `R²`.

Dodatkowo wygenerowano wykresy typu actual vs predicted, które pokazują relację między wartościami rzeczywistymi a wartościami przewidywanymi przez najlepszy model dla danej lokalizacji.

---

### Porównanie najlepszych modeli

Poniższy wykres przedstawia najlepszy model dla każdej lokalizacji według metryki `RMSE`.

![Best models summary](plots/generated/best_models_summary.png)

---

### Austin

Dla Austin najlepszy wynik uzyskał model `RidgeRegression`, osiągając `RMSE = 439.77`, `MAE = 48.16` oraz `R² = 0.999862`.

![Austin model comparison](plots/generated/austin_model_comparison.png)

Wykres actual vs predicted pokazuje dopasowanie najlepszego modelu do danych testowych.

![Austin actual vs predicted](plots/generated/actual_vs_predicted/austin_actual_vs_predicted.png)

---

### Dallas

Dla Dallas najlepszy wynik uzyskał model `RidgeRegression`, osiągając `RMSE = 68.70`, `MAE = 7.64` oraz `R² = 0.999854`.

![Dallas model comparison](plots/generated/dallas_model_comparison.png)

Wykres actual vs predicted pokazuje, że przewidywane wartości są bardzo zbliżone do wartości rzeczywistych.

![Dallas actual vs predicted](plots/generated/actual_vs_predicted/dallas_actual_vs_predicted.png)

---

### Houston

Dla Houston najlepszy wynik uzyskał model `LinearRegression`, osiągając `RMSE = 799.05`, `MAE = 130.27` oraz `R² = 0.999792`.

![Houston model comparison](plots/generated/houston_model_comparison.png)

Wykres actual vs predicted przedstawia dopasowanie modelu liniowego do danych testowych.

![Houston actual vs predicted](plots/generated/actual_vs_predicted/houston_actual_vs_predicted.png)

---

### San Antonio

Dla San Antonio najlepszy wynik uzyskał model `LinearRegression`, osiągając `RMSE = 439.41`, `MAE = 59.26` oraz `R² = 0.999863`.

![San Antonio model comparison](plots/generated/san_antonio_model_comparison.png)

Wykres actual vs predicted potwierdza bardzo dobre dopasowanie najlepszego modelu do wartości rzeczywistych.

![San Antonio actual vs predicted](plots/generated/actual_vs_predicted/san_antonio_actual_vs_predicted.png)

---

### Zbiorcze porównanie actual vs predicted

Poniższy wykres przedstawia zbiorcze porównanie wartości rzeczywistych i przewidywanych dla najlepszych modeli we wszystkich analizowanych lokalizacjach.

![All regions actual vs predicted](plots/generated/actual_vs_predicted/all_regions_actual_vs_predicted.png)

---

## Interpretacja wyników

Uzyskane wyniki wskazują, że modele liniowe najlepiej poradziły sobie z analizowanym zadaniem regresyjnym. Zarówno `LinearRegression`, jak i `RidgeRegression` osiągnęły bardzo niskie wartości błędów oraz bardzo wysokie wartości współczynnika determinacji `R²`.

W każdej lokalizacji modele regresyjne znacząco przewyższyły model bazowy `MeanBaseline`. Oznacza to, że wykorzystanie przygotowanych cech wejściowych pozwoliło znacznie poprawić jakość predykcji względem przewidywania samej średniej wartości.

Modele drzewiaste uzyskały gorsze wyniki niż modele liniowe. Może to sugerować, że w przygotowanym zbiorze danych zależności między zmiennymi wejściowymi a dziennym zapotrzebowaniem energetycznym były dobrze opisywane przez modele liniowe albo że modele drzewiaste wymagałyby dalszego strojenia hiperparametrów.

Warto również zauważyć, że Austin i San Antonio korzystają z tej samej zmiennej docelowej `scent_daily`, dlatego część wyników dla tych lokalizacji jest do siebie bardzo zbliżona. Różnice wynikają natomiast z odmiennych danych pogodowych przypisanych do tych lokalizacji.

---

## Ograniczenia projektu

Najważniejsze ograniczenia obejmują:

- wykorzystanie danych zagregowanych do poziomu dziennego,
- ograniczony zakres strojenia hiperparametrów,
- wykorzystanie dostępnych zmiennych liczbowych jako cech wejściowych,
- mapowanie miast na regiony energetyczne,
- wspólną zmienną docelową `scent_daily` dla Austin i San Antonio.

---

## Wnioski

Najważniejsze wnioski z projektu:

1. Modele liniowe osiągnęły najlepsze wyniki w analizowanym problemie.
2. `RidgeRegression` był najlepszym modelem dla Austin i Dallas.
3. `LinearRegression` był najlepszym modelem dla Houston i San Antonio.
4. Wszystkie modele regresyjne osiągnęły znacznie lepsze wyniki niż model bazowy `MeanBaseline`.
5. Wysokie wartości `R²` wskazują na bardzo dobre dopasowanie modeli do danych testowych.
6. Wykresy actual vs predicted potwierdzają, że najlepsze modele generowały predykcje bardzo bliskie wartościom rzeczywistym.

---

## Jak uruchomić projekt

Aktywacja środowiska:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

Uruchomienie modelowania:

```julia
include("src\\processing\\processing.jl")
```

Wygenerowanie wykresów porównania modeli:

```julia
include("plots\\model_results.jl")
```

Wygenerowanie wykresów actual vs predicted:

```julia
include("plots\\actual_vs_predicted.jl")
```

---

## Wyniki generowane przez projekt

Po uruchomieniu modelowania generowane są m.in. następujące pliki:

```text
data/processed/modeling/model_comparison.csv
data/processed/modeling/best_models.csv
data/processed/modeling/predictions/all_predictions.csv
data/processed/modeling/predictions/best_predictions_all.csv
```

Po uruchomieniu skryptów wizualizacyjnych generowane są m.in.:

```text
plots/generated/austin_model_comparison.png
plots/generated/dallas_model_comparison.png
plots/generated/houston_model_comparison.png
plots/generated/san_antonio_model_comparison.png
plots/generated/best_models_summary.png
plots/generated/actual_vs_predicted/austin_actual_vs_predicted.png
plots/generated/actual_vs_predicted/dallas_actual_vs_predicted.png
plots/generated/actual_vs_predicted/houston_actual_vs_predicted.png
plots/generated/actual_vs_predicted/san_antonio_actual_vs_predicted.png
plots/generated/actual_vs_predicted/all_regions_actual_vs_predicted.png
```

---

## Technologie

Projekt został wykonany w języku Julia z wykorzystaniem następujących pakietów:

- `CSV.jl`
- `DataFrames.jl`
- `MLJ.jl`
- `MLJLinearModels.jl`
- `DecisionTree.jl`
- `CairoMakie.jl`
- `StableRNGs.jl`
