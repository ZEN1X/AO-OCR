classdef DevWindow < handle
    properties
        UIFigure
        TrainButton % placeholder
        LoadModelButton % placeholder
    end

    methods
        function obj = DevWindow()
            obj.UIFigure = uifigure(Name = "Deweloper", Position = [200, 200, 300, 200], Resize = "off");

            % Layout 2x1
            gridLayout = uigridlayout(obj.UIFigure, [2, 1]);

            % Przycisk trenowania
            obj.TrainButton = uibutton(gridLayout, Text = "Trenuj sieć", ButtonPushedFcn = @(btn, event) disp("Trening..."));
            obj.TrainButton.Layout.Row = 1;

            % Przycisk ładowania modelu
            obj.LoadModelButton = uibutton(gridLayout, Text = "Załaduj model", ButtonPushedFcn = @(btn, event) disp("Ładowanie modelu..."));
            obj.LoadModelButton.Layout.Row = 2;
        end
    end
end
