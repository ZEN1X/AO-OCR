clear;
clc;
close all;

%przetwarzanie obrazu - binaryzacja, ektrakcja liter, zapis do pliku
function processImage(imagePath)
    binary_image = prepareBinaryImage(imagePath);
    [all_letters, letter_positions] = extractLetters(binary_image);
    displayLetters(all_letters);
    %saveLetterData(all_letters, letter_positions);
    saveLetterDataToMemory(all_letters, letter_positions);
end

%binaryzacja
function binary_image = prepareBinaryImage(imagePath)
    image = imread(imagePath);
    if size(image, 3) == 3
        image = rgb2gray(image);  
    end

    if max(image(:)) > 1
        image = im2double(image);
    end

    binary_image = ~imbinarize(image, graythresh(image)); 
    binary_image = bwareaopen(binary_image, 20); 
    figure;
    imshow(binary_image);
    title('Obraz po binaryzacji');
end

%ektrakcja liter i ich pozycjonowanie
function [all_letters, letter_positions] = extractLetters(binary_image)
    all_letters = {};
    letter_positions = [];
    while ~isempty(binary_image)
        [first_line, binary_image] = lines(binary_image);
        [line_letters, line_positions] = processLine(first_line);
        all_letters = [all_letters, line_letters];
        letter_positions = [letter_positions; line_positions];
    end
end

%przetwarzanie pojedynczej linii, identyfikacja liter
function [line_letters, line_positions] = processLine(line_image)
    [L, num] = bwlabel(line_image);
    props = regionprops(L, 'BoundingBox', 'Centroid', 'Area');
    props = sortComponentsByPosition(props);
    line_letters = {};
    line_positions = zeros(num, 4);
    merged = false(1, num);
    
    % Wyznaczenie średniej wysokości liter w tej linii
    letter_heights = arrayfun(@(x) x.BoundingBox(4), props); % Pobieramy wysokości liter
    average_height = mean(letter_heights); % Średnia wysokość
    fprintf('Średnia wysokość liter w linii: %.2f\n', average_height);
    
    for k = 1:num
        if merged(k)
            continue; 
        end
        [props, merged] = mergeDotsWithLetters(props, k, merged);
        letter = extractSingleLetter(line_image, props(k).BoundingBox);
        normalized_letter = resizeAndNormalizeLetter(letter, average_height); % Przekazujemy średnią wysokość
        line_letters{end + 1} = normalized_letter;
        line_positions(k, :) = props(k).BoundingBox;
    end
end




%sortowanie liter
function props = sortComponentsByPosition(props)
    horizontal_positions = arrayfun(@(x) x.BoundingBox(1), props);
    [~, sort_idx] = sort(horizontal_positions);
    props = props(sort_idx);
end 

%laczenie kropek z literami
function [props, merged] = mergeDotsWithLetters(props, k, merged)
    bbox_k = props(k).BoundingBox;
    centroid_k = props(k).Centroid;
    height_k = bbox_k(4); 
    width_k = bbox_k(3); 

    for j = 1:length(props)
        if j == k || merged(j)
            continue; 
        end

        bbox_j = props(j).BoundingBox;
        centroid_j = props(j).Centroid;
        is_dot = bbox_j(4) < 0.6 * height_k;
        horizontal_alignment = abs(centroid_j(1) - centroid_k(1)) < max(0.9 * width_k, bbox_j(3));
        is_above = centroid_j(2) < centroid_k(2); 
        vertical_distance_above = centroid_k(2) - centroid_j(2);
        is_below = centroid_j(2) > centroid_k(2); 
        vertical_distance_below = centroid_j(2) - (centroid_k(2) + height_k / 2);

        if is_above && vertical_distance_above < height_k && horizontal_alignment && is_dot
            props(k).BoundingBox = mergeBoundingBoxes(bbox_k, bbox_j);
            merged(j) = true; 
        elseif is_below && vertical_distance_below < height_k && horizontal_alignment && is_dot
            props(k).BoundingBox = mergeBoundingBoxes(bbox_k, bbox_j);
            merged(j) = true; 
        end
    end
end

%ektraktowanie pojedynczych liter na podstawie bounding box
function letter = extractSingleLetter(line_image, bbox)
    bbox = round(bbox);
    letter = imcrop(line_image, bbox);
end

%laczenie dwoch bounding boxow (kropki i litery)
function bbox = mergeBoundingBoxes(bbox1, bbox2)    
    min_x = min(bbox1(1), bbox2(1));
    max_x = max(bbox1(1) + bbox1(3), bbox2(1) + bbox2(3));
    min_y = min(bbox1(2), bbox2(2));
    max_y = max(bbox1(2) + bbox1(4), bbox2(2) + bbox2(4));
    bbox = [min_x, min_y, max_x - min_x, max_y - min_y];
end

function normalized_letter = resizeAndNormalizeLetter(letter, average_height)
    % Sprawdzenie, czy litera jest pusta
    if isempty(letter) || size(letter, 1) == 0 || size(letter, 2) == 0
        normalized_letter = zeros(32, 28, 'single');
        return;
    end

    % Pobierz wymiary litery
    [letter_height, letter_width] = size(letter);

    % Ustalenie progów dla małych i dużych liter
    small_threshold = 0.7 * average_height; % Próg dla małych liter

    if letter_height <= small_threshold
        % Skalowanie dla małych liter
        max_height = 20; % Maksymalna wysokość dla małych liter
        max_width = 18;  % Maksymalna szerokość dla małych liter
    else
        % Skalowanie dla dużych liter
        max_height = 32; % Maksymalna wysokość dla dużych liter
        max_width = 28;  % Maksymalna szerokość dla dużych liter
    end

    % Skalowanie z zachowaniem proporcji
    scale = min(max_width / letter_width, max_height / letter_height);
    scaled_letter = imresize(letter, scale);

    % Pobierz nowe wymiary po skalowaniu
    [scaled_height, scaled_width] = size(scaled_letter);

    % Przygotowanie macierzy docelowej
    resized_letter = zeros(32, 28);

    % Wycentrowanie litery w macierzy
    top_margin = max(0, floor((32 - scaled_height) / 2));
    left_margin = max(0, floor((28 - scaled_width) / 2));

    resized_letter(top_margin + 1:top_margin + scaled_height, ...
                   left_margin + 1:left_margin + scaled_width) = scaled_letter;

    % Normalizacja do zakresu [0, 1]
    normalized_letter = single(resized_letter) / 255;
end












%przeskalowywanie i normalizowanie liter
function normalized_letter2 = resizeAndNormalizeLetter2(letter)
    if isempty(letter) || size(letter, 1) == 0 || size(letter, 2) == 0
        normalized_letter = zeros(32, 28, 'single');
        return;
    end

    [letter_height, letter_width] = size(letter);
    scale = min(32 / letter_height, 28 / letter_width);
    scaled_letter = imresize(letter, scale);
    [scaled_height, scaled_width] = size(scaled_letter);
    resized_letter = zeros(32, 28);
    top_margin = max(0, floor((32 - scaled_height) / 2));
    left_margin = max(0, floor((28 - scaled_width) / 2));
    resized_letter(top_margin + 1:top_margin + scaled_height, ...
                   left_margin + 1:left_margin + scaled_width) = scaled_letter;
    normalized_letter = single(resized_letter) / 255;
    normalized_letter = imresize(normalized_letter, [32, 28]);
end

%wyswietlanie wycietych liter
function displayLetters(all_letters)
    if ~isempty(all_letters)
        figure;
        num_letters = length(all_letters);
        rows = ceil(sqrt(num_letters));
        cols = ceil(num_letters / rows);
        for idx = 1:num_letters
            subplot(rows, cols, idx);
            imshow(all_letters{idx}, []);
            title(sprintf('Litera %d', idx));
        end
    end
end

%zapisywanie liter i ich pozycji w osobnych plikach
function saveLetterData(all_letters, letter_positions)
    for idx = 1:length(all_letters)
        letter_data.letter = all_letters{idx};
        letter_data.position = letter_positions(idx, :);
        filename = sprintf('letter_%d.mat', idx);
        save(filename, '-struct', 'letter_data');
    end
    disp('Dane liter zapisane do plików .mat.');
end

%zapisywanie liter i ich pozycji do jednego pliku
function saveLetterDataToMemory2(all_letters, letter_positions)
    num_letters = length(all_letters);
    letter_matrix = zeros(32, 28, num_letters, 'single');
    for idx = 1:num_letters
        letter_matrix(:, :, idx) = all_letters{idx};
    end

    dataset.letters = letter_matrix;      
    dataset.positions = letter_positions;
    save('letters_dataset.mat', '-struct', 'dataset');
    disp('Dane liter i ich pozycji zapisane w jednym pliku letters_dataset.mat');
end

function saveLetterDataToMemory(all_letters, letter_positions)
    num_letters = length(all_letters);
    letter_matrix = zeros(32, 28, num_letters, 'single'); % Prealokacja macierzy
    for idx = 1:num_letters
        letter = all_letters{idx};
        
        % Sprawdzenie i dopasowanie wymiarów litery do 32x28
        [h, w] = size(letter);

        if h > 32 || w > 28
            % Przycięcie, jeśli litera jest za duża
            letter = imresize(letter, [min(32, h), min(28, w)]);
            [h, w] = size(letter);
        end

        % Wymuszanie dokładnego rozmiaru i marginesów
        resized_letter = zeros(32, 28, 'single');

        % Ustal marginesy, upewniając się, że są dodatnie
        top_margin = max(0, floor((32 - h) / 2));
        left_margin = max(0, floor((28 - w) / 2));

        % Wstaw litery w macierz z zachowaniem marginesów
        resized_letter(top_margin + 1:top_margin + h, ...
                       left_margin + 1:left_margin + w) = letter;

        % Przypisz literę do macierzy
        letter_matrix(:, :, idx) = resized_letter;
    end

    % Zapis liter i pozycji do pliku
    dataset.letters = letter_matrix;
    dataset.positions = letter_positions;
    save('letters_dataset.mat', '-struct', 'dataset');
    disp('Dane liter i ich pozycji zapisane w jednym pliku letters_dataset.mat');
end



%dzielenie obrazu na linie tekstu
function [fl, re] = lines(im_texto)
    im_texto = clip(im_texto); 
    num_filas = size(im_texto, 1);
    for s = 1:num_filas
        if sum(im_texto(s, :)) == 0
            nm = im_texto(1:s-1, :);
            rm = im_texto(s:end, :);
            fl = clip(nm); 
            re = clip(rm); 
            break;
        else
            fl = im_texto; 
            re = [];
        end
    end
end

%przycinanie obrazu do minimalnego prostokata
function img_out = clip(img_in)
    [f, c] = find(img_in);
    img_out = img_in(min(f):max(f), min(c):max(c)); 
end

%generowanie pliku tekstowego na obraz
function generateTextToFile(filename, textStr, fontSize, imageWidth, imageHeight, fontName)
    fig = figure('Color', 'white', 'Position', [100, 100, imageWidth, imageHeight]);
    axes('Position', [0, 0, 1, 1]);
    text(0.1, 0.5, textStr, 'FontSize', fontSize, 'FontWeight', 'bold', 'FontName', fontName);
    axis off;
    exportgraphics(fig, filename, 'Resolution', 300);
    close(fig);
    disp(['Ciąg tekstowy został zapisany jako obraz: ', filename]);
end


%processImage('ocr9.png');
processImage("imageAO.jpg")
generateTextToFile('test1.png', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ a b c d e f g h i j k l m n o p q r s t u v w x y z', 12, 1600, 200, 'Times New Roman');
processImage('test1.png')
generateTextToFile('test2.png', 'g ó w n o', 30, 8000, 200, 'Times New Roman');
processImage('test2.png')

%generateTextToFile('test3.png', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 36, 1200, 200, 'Arial');
%processImage('test3.png')
%generateTextToFile('test4.png', ' c r o s s  ! ?', 18, 8000, 200, 'Arial');
%processImage('test4.png')