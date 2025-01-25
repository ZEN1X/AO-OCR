% Uruchamiamy ten skrypt!
function main()
    % DI pattern
    % W processorze dzieje się wszystko związane z OCR
    % gui otrzymuje processor jako argument i wywołuje jego metody
    ocrProcessor = OCRProcessor();
    ocrProcessor.loadNetwork('OCR_Net.mat'); 
    gui = OCRGUI(ocrProcessor);
end
