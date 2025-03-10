classdef OCRProcessor < handle
  
    properties
        ImageMatrix          % Przechowuje oryginalny obraz wejściowy
        ExtractedLetters     % Tablica wyekstraktowanych liter (32x28x1 single)
        LetterPositions      % [x, y, szerokość, wysokość]
        TrainedNet           % Wczytany model sieci neuronowej
    end

    methods
        function setImage(obj, imageMatrix)
            % Ustawia obraz do przetworzenia
            % Input:
            %   imageMatrix - macierz obrazu w formacie RGB lub grayscale
            obj.ImageMatrix = imageMatrix;
        end

        function loadNetwork(obj, netPath)
            % Wczytuje wytrenowany model sieci neuronowej
            loaded = load(netPath);
            obj.TrainedNet = loaded.trainedNet;
            disp('Model sieci załadowany pomyślnie');
        end

        function [recognizedText, confidence] = performOCR(obj)
            % Główna metoda wykonująca pełen proces OCR
            if isempty(obj.ImageMatrix)
                error("Brak obrazu do przetworzenia. Najpierw załaduj obraz.");
            end
            if isempty(obj.TrainedNet)
                error("Najpierw załaduj model sieci neuronowej.");
            end

            binaryImage = obj.preprocessImage(obj.ImageMatrix);
            [obj.ExtractedLetters, obj.LetterPositions] = obj.extractLetters(binaryImage);
            
            [recognizedText, confidence] = obj.classifyLetters();
            %obj.visualizeExtractedLetters();
        end
        

        function binaryImage = preprocessImage(~, imageMatrix)
            % Przetwarzanie wstępne obrazu
            % Input:
            %   imageMatrix - oryginalny obraz
            % Output:
            %   binaryImage - binarny obraz po przetworzeniu
            
            % Konwersja do skali szarości dla obrazów RGB
            if size(imageMatrix, 3) == 3
                imageMatrix = rgb2gray(imageMatrix);
            end
            
            % Normalizacja do zakresu [0,1]
            if max(imageMatrix(:)) > 1
                imageMatrix = im2double(imageMatrix);
            end
            
            
            % Binaryzacja z odwróceniem (białe litery na czarnym tle)
            binaryImage = ~imbinarize(imageMatrix, graythresh(imageMatrix)*1.4);
            se = strel('rectangle', [3, 3]); % Element strukturalny do erozji
            binaryImage = imerode(binaryImage, se);
            
            % Oczyszczanie z szumu
            binaryImage = bwareaopen(binaryImage, 20);
        end
    end

    methods (Access = private)
        function visualizeExtractedLetters(obj)
            if isempty(obj.ExtractedLetters), return; end
            
            %fig = figure('Name', 'Wyekstraktowane litery', 'NumberTitle', 'off');
            num_letters = length(obj.ExtractedLetters);
            rows = floor(sqrt(num_letters));
            cols = ceil(num_letters/rows);
            
            for idx = 1:num_letters
                subplot(rows, cols, idx);
                img = obj.ExtractedLetters{idx};
                
                % Konwersja do formatu wyświetlania (odwrócenie kolorów)
                imshow(1 - img, 'InitialMagnification', 500); % 1 - img dla lepszej wizualizacji
                title(sprintf('Litera %d', idx), 'FontSize', 8);
                axis off;
            end
            sgtitle(sprintf('Wyekstraktowane litery (%d)', num_letters), 'FontSize', 12);
        end

        function [all_letters, letter_positions] = extractLetters(obj, binary_image)
            % Główna metoda ekstrakcji liter - przetwarza obraz linia po linii
            % Input:
            %   binary_image - binarny obraz wejściowy
            % Output:
            %   all_letters - lista wyekstraktowanych liter
            %   letter_positions - pozycje liter w oryginalnym obrazie
            
            all_letters = {};
            letter_positions = [];
            
            % Przetwarzanie linii tekstu aż do wyczerpania obrazu
            while ~isempty(binary_image)
                [first_line, binary_image] = obj.lines(binary_image); % Podział na linie
                [line_letters, line_positions] = obj.processLine(first_line); % Przetwarzanie linii
                
                % Agregacja wyników
                all_letters = [all_letters, line_letters];
                letter_positions = [letter_positions; line_positions];
            end
            
            % Usuwanie potencjalnych pustych komórek
            all_letters = all_letters(~cellfun('isempty', all_letters));
        end

        function [fl, re] = lines(obj, im_texto)
            % Dzieli obraz na pierwszą linię tekstu i resztę obrazu
            % Input:
            %   im_texto - binarny obraz tekstu
            % Output:
            %   fl - pierwsza linia tekstu
            %   re - pozostała część obrazu
            
            im_texto = obj.clip(im_texto); % Przycięcie białych marginesów
            num_filas = size(im_texto, 1); % Liczba wierszy w obrazie
            fl = im_texto; % Domyślnie cały obraz jako pierwsza linia
            re = [];       % Pozostała część - początkowo pusta
            
            % Szukanie pierwszej pustej linii jako separatora
            for s = 1:num_filas
                if sum(im_texto(s, :)) == 0 % Jeśli cały wiersz jest czarny
                    nm = im_texto(1:s-1, :); % Wycinek - pierwsza linia
                    rm = im_texto(s:end, :); % Reszta obrazu
                    fl = obj.clip(nm);       % Przycięcie białych marginesów
                    re = obj.clip(rm);
                    break;
                end
            end
        end

        function img_out = clip(~, img_in)
            % Przycina obraz do minimalnego prostokąta zawierającego tekst
            % Input:
            %   img_in - binarny obraz
            % Output:
            %   img_out - przycięty obraz
            
            [f, c] = find(img_in); % Znajdź współrzędne niezerowych pikseli
            if isempty(f) || isempty(c)
                img_out = []; % Obraz pusty
            else
                % Oblicz granice przycięcia
                img_out = img_in(min(f):max(f), min(c):max(c));
            end
        end

        function [line_letters, line_positions] = processLine(obj, line_image)
            % Przetwarza pojedynczą linię tekstu
            % Input:
            %   line_image - obraz pojedynczej linii
            % Output:
            %   line_letters - lista liter w linii
            %   line_positions - pozycje liter
            
            [L, num] = bwlabel(line_image); % Etykietowanie spójnych części
            props = regionprops(L, 'BoundingBox', 'Centroid', 'Area'); % Obliczanie właściwości statystycznych
            props = obj.sortComponentsByPosition(props); % Sortuj od lewej do prawej
            
            line_letters = {};
            line_positions = [];
            merged = false(1, num); % Śledzenie scalonych części

            if ~isempty(props)
                % Oblicz średnią wysokość liter w linii
                letter_heights = arrayfun(@(x) x.BoundingBox(4), props);
                
                % Przetwarzaj każdą część
                for k = 1:num
                    if merged(k), continue; end % Pomijaj scalone części
                    
                    % Scal kropki z literami (np. w 'i' lub 'j')
                    [props, merged] = obj.mergeDotsWithLetters(props, k, merged);
                    
                    % Ekstrakcja i normalizacja litery
                    letter = obj.extractSingleLetter(line_image, props(k).BoundingBox);
                    normalized_letter = obj.resizeAndNormalizeLetter(letter);
                    
                    % Zapisz wyniki
                    line_letters{end+1} = normalized_letter;
                    line_positions(end+1, :) = props(k).BoundingBox;
                end
            end
        end

        function props = sortComponentsByPosition(~, props)
            % Sortuje części od lewej do prawej
            % Input/Output:
            %   props - struktura regionprops
            
            horizontal_positions = arrayfun(@(x) x.BoundingBox(1), props);
            [~, sort_idx] = sort(horizontal_positions); % Sortowanie po pozycji X
            props = props(sort_idx);
        end

        function [props, merged] = mergeDotsWithLetters(obj, props, k, merged)
            % Scalanie kropek z odpowiadającymi literami
            % Input/Output:
            %   props - struktura regionprops
            %   k - indeks aktualnie przetwarzanej litery
            %   merged - tablica flag scalonych komponentów
            
            bbox_k = props(k).BoundingBox;
            centroid_k = props(k).Centroid;
            height_k = bbox_k(4); % Wysokość aktualnej litery
            width_k = bbox_k(3);  % Szerokość aktualnej litery

            for j = 1:length(props)
                if j == k || merged(j), continue; end % Pomijaj siebie i scalone
                
                bbox_j = props(j).BoundingBox;
                centroid_j = props(j).Centroid;
                
                % Warunki identyfikacji kropki:
                is_dot = bbox_j(4) < 0.6 * height_k;       % Wysokość < 60% litery
                horizontal_alignment = abs(centroid_j(1) - centroid_k(1)) < max(0.9*width_k, bbox_j(3));
                vertical_distance = abs(centroid_j(2) - centroid_k(2));
                
                if horizontal_alignment && is_dot && vertical_distance < height_k
                    % Scal bounding boxy
                    props(k).BoundingBox = obj.mergeBoundingBoxes(bbox_k, bbox_j);
                    merged(j) = true; % Oznacz część jako scaloną
                end
            end
        end

        function letter = extractSingleLetter(~, line_image, bbox)
            % Wycina pojedynczą literę z obrazu linii
            % Input:
            %   line_image - obraz linii tekstu
            %   bbox - współrzędne bounding box [x,y,w,h]
            % Output:
            %   letter - wycięty obraz litery
            
            bbox = round(bbox); % Zaokrąglij współrzędne do l. całkowitej
            letter = imcrop(line_image, bbox);
        end

        function bbox = mergeBoundingBoxes(~, bbox1, bbox2)
            % Łączy dwa bounding boxy w jeden
            % Input:
            %   bbox1, bbox2 - bounding boxy do scalenia
            % Output:
            %   bbox - nowy bounding box zawierający oba
            
            min_x = min(bbox1(1), bbox2(1));
            max_x = max(bbox1(1)+bbox1(3), bbox2(1)+bbox2(3));
            min_y = min(bbox1(2), bbox2(2));
            max_y = max(bbox1(2)+bbox1(4), bbox2(2)+bbox2(4));
            
            % Nowy bounding box: [x, y, szerokość, wysokość]
            bbox = [min_x, min_y, max_x-min_x, max_y-min_y];
        end

    function normalized_letter = resizeAndNormalizeLetter(~, letter)
        if isempty(letter) || all(size(letter) == 0)
            normalized_letter = ones(32, 28, 'single'); % Białe tło
            return;
        end
    
        [rows, cols] = find(letter);
        cropped_letter = letter(min(rows):max(rows), min(cols):max(cols));
        [h, w] = size(cropped_letter);
    
        if w / h < 0.3 % Specjalne traktowanie litery I
            target_height = 28;
            target_width = 18;
            scaled_letter = imresize(cropped_letter, [target_height, target_width]);
            padded_height = target_height + 4; % Dodajemy 2 piksele z góry i do
            padded_width = target_width + 4;  % Dodajemy 2 piksele z lewej i prawej
            padded_letter = ones(padded_height, padded_width, 'single');
            padded_letter(3:end-2, 3:end-2) = 1 - scaled_letter;
            resized_letter = ones(32, 28, 'single'); 
            top_margin = max(0, floor((32 - padded_height) / 2));
            left_margin = max(0, floor((28 - padded_width) / 2)); 
            resized_letter(top_margin + 1:top_margin + padded_height, ...
                           left_margin + 1:left_margin + padded_width) = padded_letter;
        else
            target_height = 32;
            target_width = 28;
            scaled_letter = imresize(cropped_letter, [target_height, target_width]);
            resized_letter = ones(32, 28, 'single'); 
            top_margin = max(0, floor((32 - target_height) / 2));
            left_margin = max(0, floor((28 - target_width) / 2));
            resized_letter(top_margin + 1:top_margin + target_height, ...
                           left_margin + 1:left_margin + target_width) = 1 - scaled_letter; % Czarna litera na białym tle
        end
        normalized_letter = resized_letter;
    end

        function [text, confidence] = classifyLetters(obj)
            numLetters = length(obj.ExtractedLetters);
            text = '';
            confidence = zeros(1, numLetters);
            
            for i = 1:numLetters
                letterImage = obj.ExtractedLetters{i};
                
                letterImage = reshape(letterImage, [32, 28, 1, 1]);
                
                [predictedLabel, scores] = classify(obj.TrainedNet, letterImage);
                [~, idx] = max(scores);
                
                text = [text char(predictedLabel)];
                confidence(i) = scores(idx);
            end
        end
    end
end
