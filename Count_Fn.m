function [cellcount_area, gut_area] = Count_Fn(IMAGE)

% Count_Fn function reads IMAGE then returns cell count and region of interest area.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bonirath Chhay
% July 2018
% File name: Count_Fn.m. 

% Usage: Use with Count_Wrapper.m. Originally developed to count bacteria cells in confocal micrographs of fluorescent bacteria in Nasonia larval gut. 
% Customize values where noted with "CUSTOMIZE".
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Importing Images

% Importing original image from spreadsheet list.
ori_img = imread(IMAGE);

%% Convert RGB Images to Grayscale

% Convert original RGB 3-D images to grayscale (0 to 256 -> 0 to 1)
gray_img = rgb2gray(ori_img);

%% Check for Signal of Interest

signal_intensity = 159;  % CUSTOMIZE FOR SIGNAL OF INTEREST
value = signal_intensity + 1; 
% Check for signal of interest. Terminate if not present; continue if present. 
if counts(value) == 0; 
    % Set the cell count and gut area as 0 and no further processing.
    cellcount_area = 0; 
    gut_area = 0; % 
else
    %% Overlay scale bar region with black mask
    
    img_dimension = 512;  % CUSTOMIZE WITH IMAGE PIXEL DIMENSION
    
    % Create matrix that is black where scale bar is and white otherwise.
    scalebar_mask = ones(img_dimension, img_dimension); 
    % Make scale bar region black (0). Default location is bottom-right. 
    scalebar_mask([450:512], [450:512]) = 0; % CUSTOMIZE FOR SCALE BAR LOCATION.
    % Convert from double to uint8 to multiply with image.
    scalebar_mask = uint8(scalebar_mask); 

    % Multiply scale bar mask by original grayscale image.
    gray_img = immultiply(scalebar_mask),gray_img);
  
    %% Isolate Regions of Bacteria 
    
    low_signal = 124;  % CUSTOMIZE WITH LOWER BOUND ON RANGE FOR SIGNAL OF INTEREST.
    high_signal = 161;  % CUSTOMIZE WITH UPPER BOUND ON RANGE FOR SIGNAL OF INTEREST.
    % Create bacteria intensity mask.
    isbacteria = (gray_img > low_signal & gray_img < high_signal); 
    % Multiply mask and image to produce image with only bacteria signal. 
    onlybacteria_img = immultiply(isbacteria, gray_img); 

    %% Isolate Region of Gut

    low_background = 24; % CUSTOMIZE WITH LOWER BOUND ON RANGE FOR BACKGROUND OF INTEREST.
    high_background = 161; % CUSTOMIZE WITH UPPER BOUND ON RANGE FOR BACKGROUND OF INTEREST.
    % Create gut intensity mask. 
    isgut = (gray_img > low_background & gray_img < high_background); 
    % Multiply mask and image to produce image with only gut region. 
    gut_img = immultiply(isgut, gray_img); 

    %% Remove Noise Pixels In Gut By Size
    
    % Binarize gut image to use with bwconncomp().
    bw_gut_img = imbinarize(gut_img);
    % In image, find number of 8-connectivity components and pixel ID. 
    CC_gut =  bwconncomp(bw_gut_img);
    numPixels_gut = cellfun(@numel,CC_gut.PixelIdxList);
    % Set size of stray pixel.
    stray_pxs = 20;  % CUSTOMIZE 
    % While size of connected pixels is less than the size of stray pixels,  
    while min(numPixels_gut) < stray_pxs
        numPixels_gut = cellfun(@numel,CC_gut.PixelIdxList); 
        % find the smallest pixel number and its index location.
        [smallest,idx] = min(numPixels_gut);
        % If none found, then break out of while loop. 
        if isempty(idx) == 1 
            CC_gut =  bwconncomp(bw_gut_img);
        else
            % Otherwise, set that pixels to 0 (black). 
            bw_gut_img(CC_gut.PixelIdxList{idx}) = 0;
        end
    end

    %% Dilate Pixel Distances and Infill Gut Area
    
    % Vertical dilation, size 6.
    dilate90 = strel('line', 6, 90); 
    % Horizonal dilation, size 6.
    dilate0 = strel('line', 6, 0); 

    % Apply vertical and horizontal dilation to pixels. 
    bw_gut_dilated_img = imdilate(bw_gut_img, [dilate90 dilate0]); 

    % Infill gut area. 
    bw_gut_img = imfill(bw_gut_dilated_img,'holes'); 

    %% Find Area of Gut
    
    % Area in pixels, of infilled gut
    gut_area = bwarea(bw_gut_img); 

    %% Outline Gut Boundary
    
    % Update CC_gut struct with updated infilled gut matrix.
    CC_gut =  bwconncomp(bw_gut_img);
    % Label gut image with CC values. 
    labeledgut_img = labelmatrix(CC_gut);
    % Extract the labeled matrix for the gut and outline.
    [trace_gut, matrix_gut] = bwboundaries(bw_gut_img,'noholes');
    % Label image with autumn colormap and black background.  
    gutoutline_img = label2rgb(matrix_gut, @autumn, [0 0 0]);
    % Label the original with the gut outline
    hold on
    for k = 1:length(trace_gut)
       boundary = trace_gut{k};
       plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
    end
    hold off
    %%%%
    close

    %% Multiply  gut mask and bacteria images to determine colocalization 
    
    % Multiply gut mask and bacteria images to get bacteria in gut only
    colocalization_img = immultiply(bw_gut_img, onlybacteria_img); %  grayscale image

    %% Remove Single Pixels from Bacteria Image.

    % Find number of 8-connectivity components and pixel ID in image.
    CC =  bwconncomp(colocalization_img);

    % Remove single pixels. 
    numPixels = cellfun(@numel,CC.PixelIdxList);
    % while smallest number of pixels in connected component is < 2, 
    while min(numPixels) < 2
        numPixels = cellfun(@numel,CC.PixelIdxList); 
        % find the smallest pixel number and its index location.
        [smallest,idx] = min(numPixels);
        % If there is none, then break out of loop.
        if isempty(idx) == 1 
            CC =  bwconncomp(colocalization_img);
        else
            % Set that pixel to 0 (black). 
            colocalization_img(CC.PixelIdxList{idx}) = 0;
        end
    end

    %% Find Cell Count Using Region of Interest 
    
    % Find area of region of interest (white regions) in binary image.
    Area = bwarea(colocalization_img);
    % Average area of single cell, in pixels. 
    singlecell_area = 3; % CUSTOMIZE WITH SIZE OF CELL. 
    % Find cell count. 
    cellcount_area = Area/singlecell_area; 
    
end % the outermost end that wraps the entire processing algorithm

