# Projekt OCR w MATLAB - rozpoznawanie logo firm

## Instrukcja użytkowania

1. **Uruchomienie GUI:**
   - Skrypt `main.m` inicjalizuje interfejs GUI oraz procesor OCR.
2. **Załadowanie obrazu:**
   - Należy kliknąć przycisk `Załaduj obraz` i wybrać plik w formatach PNG, JPG lub BMP.
   - Obraz zostanie załadowany i wyświetlony w sekcji obrazu.
3. **Uruchomienie OCR:**
   - Po załadowaniu obrazu należy kliknąć `Uruchom OCR`.
   - Wynik zostanie wyświetlony w polu tekstowym.
4. **Dodatkowe opcje:**
   - Przycisk `Deweloper`, otwiera okno z zaawansowanymi funkcjami - ładowanie modelu, trening.

--

## Architektura systemu

System OCR składa się z graficznego interfejsu użytkownika (GUI) oraz procesora OCR. GUI, zaprojektowane w MATLAB przy użyciu funkcji `uifigure`, umożliwia intuicyjne ładowanie obrazów, uruchamianie procesu rozpoznawania oraz przeglądanie wyników. Procesor OCR przetwarza obrazy i klasyfikuje znaki za pomocą wytrenowanej sieci neuronowej, co zapewnia modularność i łatwość utrzymania systemu.

## Sieć neuronowa

Sieć neuronowa w projekcie OCR jest dwuwarstwową konwolucyjną siecią neuronową. Posiada warstwy stabilizujące proces uczenia, co zwiększa dokładność rozpoznawania.

## Przetwarzanie obrazów

Proces przetwarzania obrazów w OCR obejmuje binaryzację, co oddziela litery od tła, ekstrakcję i sortowanie liter oraz ich normalizację do standardowego rozmiaru 32x28 pikseli. Dodatkowo, małe komponenty, takie jak kropki, są łączone z literami, co jest kluczowe dla poprawnego rozpoznawania nietypowych znaków.

## Testowanie i Walidacja

System OCR został przetestowany na różnych obrazach z różnymi czcionkami i rozmiarami tekstu, co potwierdziło jego skuteczność w rozpoznawaniu liter i cyfr. Proces normalizacji i skalowania liter poprawił wyniki klasyfikacji, minimalizując wpływ zmiennych rozmiarów i proporcji znaków.

## Integracja z graficznym interfejsem użytkownika

Graficzny interfejs użytkownika został połączony z procesorem OCR, umożliwiając użytkownikowi łatwe ładowanie obrazów, uruchamianie rozpoznawania oraz przeglądanie wyników. Przyciski `Załaduj obraz`, `Uruchom OCR` oraz `Deweloper` pozwalają na wybór pliku, rozpoczęcie procesu OCR oraz dostęp do zaawansowanych funkcji, takich jak ładowanie modeli czy trening sieci neuronowej.

---

## Autorzy

- **Jan Kwiatkowski** 
- **Aleksander Kopyto**
- **Helena Jońca**
- **Julia Przeździk** 

---

