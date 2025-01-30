classdef K_Means_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        TabGroup                       matlab.ui.container.TabGroup
        DATAACQUISITIONTab             matlab.ui.container.Tab
        GridLayout2                    matlab.ui.container.GridLayout
        GeneratingDataPanel            matlab.ui.container.Panel
        GridLayout4                    matlab.ui.container.GridLayout
        UploadGenerateddataButton      matlab.ui.control.StateButton
        GenerateDataButton             matlab.ui.control.Button
        NClustersEditField             matlab.ui.control.NumericEditField
        NClustersEditFieldLabel        matlab.ui.control.Label
        NInstancesEditField            matlab.ui.control.NumericEditField
        NInstancesEditFieldLabel       matlab.ui.control.Label
        NFeaturesEditField             matlab.ui.control.NumericEditField
        NFeaturesEditFieldLabel        matlab.ui.control.Label
        UploadingDataPanel             matlab.ui.container.Panel
        GridLayout3                    matlab.ui.container.GridLayout
        FileNameEditFieldLabel         matlab.ui.control.Label
        UploadFileButton               matlab.ui.control.Button
        FileNameEditField              matlab.ui.control.EditField
        UITable                        matlab.ui.control.Table
        KMEANSTab                      matlab.ui.container.Tab
        GridLayout5                    matlab.ui.container.GridLayout
        UITable2                       matlab.ui.control.Table
        CalculateOptimalKButtonPushed  matlab.ui.control.Button
        OptimalKEditField              matlab.ui.control.EditField
        LenombredeclusteroptimaldapreslamethodedelasiLabel  matlab.ui.control.Label
        UIAxes                         matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
        Data    
        Labels
        predicted % Description
    end
    
    methods (Access = public)
        
        function updateTable(app)
            try
                % Vérifier si les données existent
                if ~isempty(app.Data) && ~isempty(app.predicted)
                    % Obtenir le nombre de features de manière sécurisée
                    nFeatures = size(app.Data, 2); % Utiliser directement la taille des données
                    
                    % Créer les noms des colonnes pour les features
                    featureNames = {};
                    for i = 1:nFeatures
                        featureNames{end+1} = ['Feature', num2str(i)];
                    end
                    
                    % Créer une table avec les données originales
                    dataTable = array2table(app.Data);
                    
                    % Renommer les colonnes de la table
                    dataTable.Properties.VariableNames = featureNames;
                    
                    % Ajouter la colonne des clusters prédits
                    dataTable.Cluster = app.predicted;
                    
                    % Mettre à jour UITable2 avec les nouvelles données
                    app.UITable2.Data = table2cell(dataTable);
                    
                    % Définir les noms des colonnes
                    app.UITable2.ColumnName = [featureNames, {'Cluster'}];
                    
                    % Ajuster la largeur des colonnes
                    columnWidths = repmat({120}, 1, nFeatures);
                    columnWidths{end+1} = 80; % Pour la colonne Cluster
                    app.UITable2.ColumnWidth = columnWidths;
                else
                    % Message d'erreur pour données manquantes
                    if isempty(app.Data)
                        msgbox('Les données sont manquantes.', 'Erreur', 'error');
                    elseif isempty(app.predicted)
                        msgbox('Les clusters prédits sont manquants.', 'Erreur', 'error');
                    end
                end
            catch ME
                % Afficher l'erreur dans une boîte de dialogue
                msgbox(['Erreur lors de la mise à jour du tableau : ' ME.message], 'Erreur', 'error');
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: UploadFileButton
        function UploadFileButtonPushed(app, event)
            [file, path] = uigetfile({'*.csv;*.xls;*.xlsx', 'Data Files (*.csv, *.xls, *.xlsx)'});
            if isequal(file, 0)
                return;
            end
            app.FileNameEditField.Value = file ;
            fullPath = fullfile(path, file);
            data = readtable(fullPath);
            app.Data = data;
            app.UITable.Data = data;
        end

        % Button pushed function: GenerateDataButton
        function GenerateDataButtonPushed(app, event)
            nClusters = app.NClustersEditField.Value;
            nInstances = app.NInstancesEditField.Value;
            nFeatures = app.NFeaturesEditField.Value;
            function [data, labels] = generateClusteredData(nFeatures, nInstances, nClusters)
                instancesPerCluster = floor(nInstances / nClusters);
                data = zeros(nInstances, nFeatures);
                labels = zeros(nInstances, 1);
                clusterCenters = randn(nClusters, nFeatures) * sqrt(nFeatures) * 2;
                for i = 1:nClusters
                    startIdx = (i-1) * instancesPerCluster + 1;
                    endIdx = i * instancesPerCluster;
                    noise = randn(instancesPerCluster, nFeatures);
                    data(startIdx:endIdx, :) = noise + repmat(clusterCenters(i,:), instancesPerCluster, 1);
                    labels(startIdx:endIdx) = i;
                end
                remaining = nInstances - (instancesPerCluster * nClusters);
                if remaining > 0
                    startIdx = (nClusters * instancesPerCluster) + 1;
                    
                    % Génération des points restants
                    remainingPoints = randn(remaining, nFeatures) * 5;
                    remainingLabels = randi(nClusters, remaining, 1);
                    
                    % Ajout des points restants
                    data(startIdx:end, :) = remainingPoints;
                    labels(startIdx:end) = remainingLabels;
                end
            end
            [data,labels] = generateClusteredData(nClusters, nInstances, nFeatures);
            app.Data = data;     
            app.Labels = labels;
            app.UITable.Data = data;
        end

        % Value changed function: UploadGenerateddataButton
        function UploadGenerateddataButtonValueChanged(app, event)
            [file, path] = uiputfile('*.csv', 'Save Matrix as .csv File');
        
            if isequal(file, 0)
                disp('User canceled the operation.');
            else
                writematrix(app.Data, fullfile(path, file));
                disp(['Matrix saved to ', fullfile(path, file)]);
            end
            
            msgbox('Data saved successfully!', 'Success');
        end

        % Value changed function: OptimalKEditField
        function OptimalKEditFieldValueChanged(app, event)

        end

        % Button pushed function: CalculateOptimalKButtonPushed
        function CalculateOptimalKButtonPushedPushed(app, event)
                % Plage de valeurs pour k (exclure k = 1)
                k_range = 2:10;
                
                % Vérifier si les données sont disponibles
                if isempty(app.Data)
                    uialert(app.UIFigure, 'Les données sont vides. Veuillez charger des données valides.', 'Erreur');
                    return;
                end
                
                % Initialiser un tableau pour stocker les scores de silhouette
                silhouette_scores = zeros(length(k_range), 1);
                
                % Calcul des scores de silhouette pour chaque k
                for i = 1:length(k_range)
                    k = k_range(i);
                    try
                        % Appliquer K-means
                        [cluster_idx, ~] = kmeans(app.Data, k);
                        % Calculer le score moyen de la silhouette
                        silhouette_scores(i) = mean(silhouette(app.Data, cluster_idx));
                    catch ME
                        uialert(app.UIFigure, sprintf('Erreur pour k = %d : %s', k, ME.message), 'Erreur');
                        return;
                    end
                end
                
                % Trouver le nombre optimal de clusters
                [~, best_k_idx] = max(silhouette_scores);
                best_k = k_range(best_k_idx);
                
                % Mettre à jour le champ OptimalK
                app.OptimalKEditField.Value = num2str(best_k);

                [cluster_idx, ~] = kmeans(app.Data, best_k);
                app.predicted = cluster_idx;
                updateTable(app);
                cla(app.UIAxes);
    
                % Créer des points d'interpolation pour une courbe lisse
                k_interp = linspace(min(k_range), max(k_range), 100);
                scores_interp = spline(k_range, silhouette_scores, k_interp);
                
                % Tracer la courbe continue interpolée
                plot(app.UIAxes, k_interp, scores_interp, 'b-', 'LineWidth', 1.5);
                hold(app.UIAxes, 'on');
                
                % Ajouter les points de données originaux
                plot(app.UIAxes, k_range, silhouette_scores, 'o', ...
                    'MarkerEdgeColor', 'blue', ...
                    'MarkerFaceColor', 'white', ...
                    'MarkerSize', 8);
                
                % Personnaliser l'apparence
                title(app.UIAxes, 'Évaluation du nombre optimal de clusters', 'FontSize', 12);
                xlabel(app.UIAxes, 'Nombre de clusters (k)', 'FontSize', 10);
                ylabel(app.UIAxes, 'Score de silhouette moyen', 'FontSize', 10);
                
                % Configurer la grille et les axes
                grid(app.UIAxes, 'on');
                app.UIAxes.GridAlpha = 0.3;
                app.UIAxes.Box = 'on';
                
                % Définir les limites des axes
                ylim(app.UIAxes, [0 1]);
                xlim(app.UIAxes, [2 9]);
                
                % Configurer les ticks des axes
                app.UIAxes.XTick = 2:9;
                app.UIAxes.YTick = 0:0.1:1;
                
                % Ajouter une toolbar de navigation
                app.UIAxes.Toolbar.Visible = 'on';
                
                hold(app.UIAxes, 'off');

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1085 438];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.HandleVisibility = 'callback';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create DATAACQUISITIONTab
            app.DATAACQUISITIONTab = uitab(app.TabGroup);
            app.DATAACQUISITIONTab.Title = 'DATA ACQUISITION';

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.DATAACQUISITIONTab);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.GridLayout2.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout2.RowSpacing = 0;
            app.GridLayout2.HandleVisibility = 'callback';

            % Create UITable
            app.UITable = uitable(app.GridLayout2);
            app.UITable.BackgroundColor = [1 1 1;0.9412 0.9412 0.9412];
            app.UITable.ColumnName = '';
            app.UITable.RowName = {};
            app.UITable.Layout.Row = [5 7];
            app.UITable.Layout.Column = [1 5];

            % Create UploadingDataPanel
            app.UploadingDataPanel = uipanel(app.GridLayout2);
            app.UploadingDataPanel.Title = 'Uploading Data';
            app.UploadingDataPanel.Layout.Row = [1 2];
            app.UploadingDataPanel.Layout.Column = [1 5];

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.UploadingDataPanel);
            app.GridLayout3.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout3.RowHeight = {'1x', '1x', '1x'};
            app.GridLayout3.RowSpacing = 0;
            app.GridLayout3.Padding = [10 0 10 0];

            % Create FileNameEditField
            app.FileNameEditField = uieditfield(app.GridLayout3, 'text');
            app.FileNameEditField.HorizontalAlignment = 'center';
            app.FileNameEditField.Layout.Row = 2;
            app.FileNameEditField.Layout.Column = [5 8];

            % Create UploadFileButton
            app.UploadFileButton = uibutton(app.GridLayout3, 'push');
            app.UploadFileButton.ButtonPushedFcn = createCallbackFcn(app, @UploadFileButtonPushed, true);
            app.UploadFileButton.Layout.Row = 2;
            app.UploadFileButton.Layout.Column = 3;
            app.UploadFileButton.Text = 'Upload File';

            % Create FileNameEditFieldLabel
            app.FileNameEditFieldLabel = uilabel(app.GridLayout3);
            app.FileNameEditFieldLabel.HorizontalAlignment = 'right';
            app.FileNameEditFieldLabel.Layout.Row = 2;
            app.FileNameEditFieldLabel.Layout.Column = 4;
            app.FileNameEditFieldLabel.Text = 'File Name :';

            % Create GeneratingDataPanel
            app.GeneratingDataPanel = uipanel(app.GridLayout2);
            app.GeneratingDataPanel.Title = 'Generating Data';
            app.GeneratingDataPanel.Layout.Row = [3 4];
            app.GeneratingDataPanel.Layout.Column = [1 5];

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.GeneratingDataPanel);
            app.GridLayout4.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout4.RowHeight = {'1x', '1x', '1x'};
            app.GridLayout4.RowSpacing = 0;
            app.GridLayout4.Padding = [10 0 10 0];

            % Create NFeaturesEditFieldLabel
            app.NFeaturesEditFieldLabel = uilabel(app.GridLayout4);
            app.NFeaturesEditFieldLabel.HorizontalAlignment = 'right';
            app.NFeaturesEditFieldLabel.Layout.Row = 1;
            app.NFeaturesEditFieldLabel.Layout.Column = 2;
            app.NFeaturesEditFieldLabel.Text = 'N° Features :';

            % Create NFeaturesEditField
            app.NFeaturesEditField = uieditfield(app.GridLayout4, 'numeric');
            app.NFeaturesEditField.Layout.Row = 1;
            app.NFeaturesEditField.Layout.Column = 3;

            % Create NInstancesEditFieldLabel
            app.NInstancesEditFieldLabel = uilabel(app.GridLayout4);
            app.NInstancesEditFieldLabel.HorizontalAlignment = 'right';
            app.NInstancesEditFieldLabel.Layout.Row = 2;
            app.NInstancesEditFieldLabel.Layout.Column = 2;
            app.NInstancesEditFieldLabel.Text = 'N° Instances :';

            % Create NInstancesEditField
            app.NInstancesEditField = uieditfield(app.GridLayout4, 'numeric');
            app.NInstancesEditField.Layout.Row = 2;
            app.NInstancesEditField.Layout.Column = 3;

            % Create NClustersEditFieldLabel
            app.NClustersEditFieldLabel = uilabel(app.GridLayout4);
            app.NClustersEditFieldLabel.HorizontalAlignment = 'right';
            app.NClustersEditFieldLabel.Layout.Row = 3;
            app.NClustersEditFieldLabel.Layout.Column = 2;
            app.NClustersEditFieldLabel.Text = 'N° Clusters :';

            % Create NClustersEditField
            app.NClustersEditField = uieditfield(app.GridLayout4, 'numeric');
            app.NClustersEditField.AllowEmpty = 'on';
            app.NClustersEditField.Layout.Row = 3;
            app.NClustersEditField.Layout.Column = 3;

            % Create GenerateDataButton
            app.GenerateDataButton = uibutton(app.GridLayout4, 'push');
            app.GenerateDataButton.ButtonPushedFcn = createCallbackFcn(app, @GenerateDataButtonPushed, true);
            app.GenerateDataButton.Layout.Row = 2;
            app.GenerateDataButton.Layout.Column = 5;
            app.GenerateDataButton.Text = 'Generate Data';

            % Create UploadGenerateddataButton
            app.UploadGenerateddataButton = uibutton(app.GridLayout4, 'state');
            app.UploadGenerateddataButton.ValueChangedFcn = createCallbackFcn(app, @UploadGenerateddataButtonValueChanged, true);
            app.UploadGenerateddataButton.Text = 'Upload Generated data';
            app.UploadGenerateddataButton.Layout.Row = 2;
            app.UploadGenerateddataButton.Layout.Column = [7 8];

            % Create KMEANSTab
            app.KMEANSTab = uitab(app.TabGroup);
            app.KMEANSTab.Title = 'K-MEANS';

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.KMEANSTab);
            app.GridLayout5.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.GridLayout5.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout5);
            title(app.UIAxes, 'Méthode de silhouette')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Layout.Row = [2 7];
            app.UIAxes.Layout.Column = [1 2];

            % Create LenombredeclusteroptimaldapreslamethodedelasiLabel
            app.LenombredeclusteroptimaldapreslamethodedelasiLabel = uilabel(app.GridLayout5);
            app.LenombredeclusteroptimaldapreslamethodedelasiLabel.HorizontalAlignment = 'right';
            app.LenombredeclusteroptimaldapreslamethodedelasiLabel.FontSize = 18;
            app.LenombredeclusteroptimaldapreslamethodedelasiLabel.Layout.Row = 1;
            app.LenombredeclusteroptimaldapreslamethodedelasiLabel.Layout.Column = [2 4];
            app.LenombredeclusteroptimaldapreslamethodedelasiLabel.Text = 'Le nombre de cluster optimal d''apres la methode de la silhouette est : ';

            % Create OptimalKEditField
            app.OptimalKEditField = uieditfield(app.GridLayout5, 'text');
            app.OptimalKEditField.ValueChangedFcn = createCallbackFcn(app, @OptimalKEditFieldValueChanged, true);
            app.OptimalKEditField.HorizontalAlignment = 'center';
            app.OptimalKEditField.FontSize = 18;
            app.OptimalKEditField.Layout.Row = 1;
            app.OptimalKEditField.Layout.Column = 5;

            % Create CalculateOptimalKButtonPushed
            app.CalculateOptimalKButtonPushed = uibutton(app.GridLayout5, 'push');
            app.CalculateOptimalKButtonPushed.ButtonPushedFcn = createCallbackFcn(app, @CalculateOptimalKButtonPushedPushed, true);
            app.CalculateOptimalKButtonPushed.FontSize = 18;
            app.CalculateOptimalKButtonPushed.Layout.Row = 1;
            app.CalculateOptimalKButtonPushed.Layout.Column = 1;
            app.CalculateOptimalKButtonPushed.Text = 'Calculer K-optimal';

            % Create UITable2
            app.UITable2 = uitable(app.GridLayout5);
            app.UITable2.ColumnName = '';
            app.UITable2.RowName = {};
            app.UITable2.Layout.Row = [2 7];
            app.UITable2.Layout.Column = [3 5];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = K_Means_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end