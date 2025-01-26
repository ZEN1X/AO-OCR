classdef OCRGUI < handle
    % Całe GUI zrobione korzystając z uifigure
    % https://www.mathworks.com/help/matlab/develop-apps-using-the-uifigure-function.html

    properties
        UIFigure
        ImageDisplay
        OCRTextArea
        LoadButton
        OCRButton
        DevButton
        OCRProcessor
        OriginalImage
    end

    methods
        % Konstruktor
        function obj = OCRGUI(ocrProcessor)
            obj.OCRProcessor = ocrProcessor;

            % Główne okno
            obj.UIFigure = uifigure(Name = "AO_OCR", Position = [100, 100, 500, 600], Icon='assets/icon.png');

            % Layout główny
            gridLayout = uigridlayout(obj.UIFigure, [3, 1], RowHeight = {'3x', '1x', 80}, ColumnWidth = {'1x'});

            % Obrazek
            obj.ImageDisplay = uiimage(gridLayout);
            obj.ImageDisplay.Layout.Row = 1;

            % Wynik OCR
            obj.OCRTextArea = uitextarea(gridLayout, ...
                HorizontalAlignment = "center", ...
                FontSize = 14, ...
                Editable = "off", ...
                Value = "Wynik OCR pojawi się tutaj...", ...
                BackgroundColor = [0.9, 0.9, 0.9]);
            obj.OCRTextArea.Layout.Row = 2;

            % Layout przycisków
            buttonsLayout = uigridlayout(gridLayout, [1, 3], ColumnWidth = {'1x', '1x', '1x'});
            buttonsLayout.Layout.Row = 3;

            % Przycisk deweloperski
            obj.DevButton = uibutton(buttonsLayout, Text = "Deweloper", ...
                ButtonPushedFcn = @(btn, event) obj.openDevWindow());
            obj.DevButton.Layout.Column = 1;

            % Przycisk ładowania obrazka
            obj.LoadButton = uibutton(buttonsLayout, Text = "Załaduj obraz", ...
                ButtonPushedFcn = @(btn, event) obj.loadImage());
            obj.LoadButton.Layout.Column = 2;

            % Przycisk OCR
            obj.OCRButton = uibutton(buttonsLayout, Text = "Uruchom OCR", ...
                ButtonPushedFcn = @(btn, event) obj.runOCR());
            obj.OCRButton.Layout.Column = 3;
        end

        % Ładowanie obrazka
        function loadImage(obj)
            [file, path] = uigetfile({'*.png;*.jpg;*.bmp', 'Pliki obrazów (*.png, *.jpg, *.bmp)'});
            if file % Użytkownik załadował obrazek
                imagePath = fullfile(path, file);
                obj.OriginalImage = imread(imagePath);
                obj.ImageDisplay.ImageSource = imagePath; % Ustawia obrazek w GUI

                % Ustawia obrazek w OCRProcessorze
                obj.OCRProcessor.setImage(obj.OriginalImage);
                obj.OCRTextArea.Value = "Obrazek załadowany. Kliknij 'Uruchom OCR', aby rozpocząć przetwarzanie.";
            else % Użytkownik zamknął file-picker
                obj.OCRTextArea.Value = "Użytkownik anulował ładowanie obrazka.";
            end
        end

        % OCR
        function runOCR(obj)
            try
                result = obj.OCRProcessor.performOCR();
                obj.OCRTextArea.Value = result;
            catch ME
                obj.OCRTextArea.Value = ME.message;
            end
        end

        % Okienko do ładowania modelu etc.
        function openDevWindow(obj)
            DevWindow();
        end
    end
end
