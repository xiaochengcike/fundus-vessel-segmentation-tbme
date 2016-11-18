
function [results] = runVesselSegmentationUsingExistingModel(config, model)
    
    % if there are labels in the test data
    if config.thereAreLabelsInTheTestData
        % Open training data labels
        allLabels = openVesselLabels(fullfile(config.test_data_path, 'labels'));
    else
        allLabels = [];
    end

    % set image and mask paths
    imagesPath = fullfile(config.test_data_path, 'images');
    masksPath = fullfile(config.test_data_path, 'masks');
    
    % retrieve image names...
    imgNames = getMultipleImagesFileNames(imagesPath);
    % ...and mask names
    mskNames = getMultipleImagesFileNames(masksPath);
    
    % for each image, verify if the feature file exist. if it is not there,
    % then we should compute it
    for i = 1 : length(imgNames)

        fprintf('Extracting features from %i/%i\n',i,length(imgNames));
        
        % open the mask
        mask = imread(fullfile(masksPath, mskNames{i})) > 0;
        mask = mask(:,:,1);
        testdata.masks{1} = mask;

        % UNARY FEATURES --------------------------------------------------
        selectedFeatures = config.features.unary.unaryFeatures;
        config2 = config;
        
        % Remove features we will not include
        config2.features.features(selectedFeatures==0) = [];
        config2.features.featureParameters(selectedFeatures==0) = [];
        config2.features.featureNames(selectedFeatures==0) = [];
        
        fprintf(strcat('Computing unary features\n'));
        % get the features of this image
        testdata.unaryFeatures = extractFeaturesFromSingleImage(imagesPath, imgNames{i}, mask, config2, true);
        % get features dimensionality
        config.features.unary.unaryDimensionality = size(testdata.unaryFeatures, 2);
        %
        if (~iscell(testdata.unaryFeatures))
            testdata.unaryFeatures = {testdata.unaryFeatures};
        end
        % get image filename
        filename = imgNames{i};
        if (~iscell(filename))
            testdata.filenames = {filename(1:end-4)};
        else
            testdata.filenames = filename(1:end-4);
        end
        
        % PAIRWISE FEATURES -----------------------------------------------
        selectedFeatures = config.features.pairwise.pairwiseFeatures;
        config2 = config;
        
        % Remove features we will not include
        config2.features.features(selectedFeatures==0) = [];
        config2.features.featureParameters(selectedFeatures==0) = [];
        config2.features.featureNames(selectedFeatures==0) = [];
        
        fprintf(strcat('Computing pairwise features\n'));
        % get the features of this image
        pairwisefeatures = {extractFeaturesFromSingleImage(imagesPath, imgNames{i}, mask, config2, false)};
        % get features dimensionality
        config.features.unary.pairwiseDimensionality = size(pairwisefeatures, 2);
        % compute the pairwise kernels
        testdata.pairwiseKernels = getPairwiseFeatures(pairwisefeatures, config.features.pairwise.pairwiseDeviations);
        % get current label
        if ~isempty(allLabels)
            testdata.labels{1} = allLabels{i};
        end
        
        % Segment test data to evaluate the model -------------------------
        [results.segmentations, results.qualityMeasures] = getBunchSegmentations2(config, testdata, model);
        
        % Save the segmentations ------------------------------------------
        SaveSegmentations(config.resultsPath, config, results, model, testdata.filenames);
        
    end
    
end