classdef OCRProcessor < handle
    properties
        ImageMatrix
    end

    methods
        % Ustawienie obrazu
        function setImage(obj, imageMatrix)
            obj.ImageMatrix = imageMatrix;
        end

        % Przetwarzanie OCR
        function recognizedText = performOCR(obj)
            if isempty(obj.ImageMatrix)
                error("Brak obrazu do przetworzenia. Najpierw załaduj obraz.");
            end

            % placeholder
            disp("Przygotowywanie obrazu...");
            processedImage = obj.preprocessImage(obj.ImageMatrix);

            % placeholder
            disp("Wykonywanie OCR...");
            pause(1); % symulacja OCR
            recognizedText = "Przykładowy wykryty tekst po przetwarzaniu.";
        end

        % Przygotowanie obrazu do rozpoznawania
        function processedImage = preprocessImage(~, imageMatrix)
            disp("Stosowanie przekształceń...");
            processedImage = rgb2gray(imageMatrix);
        end
    end
end
