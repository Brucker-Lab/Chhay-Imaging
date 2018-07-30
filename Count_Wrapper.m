
% Prints out cell count (Column 1) and gut area (Column 2) results for each image in z-stack and sum (last row) to a new Output.csv file.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bonirath Chhay
% July 2018
% File name: Count_Wrapper.m. 

% Usage: Run this file with Count_Fn.m in directory. 
% Customize values where noted with "CUSTOMIZE".
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Clear all, close all

clear all
close all

%% Read Through Image File Names To Be Run Through Function

% First, import all images in list to same directory. 

% Read file containing image file names in a column. 
[num, file] = xlsread('20180310_zstack_A.xlsx');  % CUSTOMIZE INPUT LIST FILE NAME.

% Determine number of image files in list. 
file_count = length(file);

% For each image file in list, write the 2 function outputs to the results array. 
for i=1:file_count
    [cellcount_area(i),gut_area(i)] = CellCount_Fn(char(file{i,1}));
end

%% Find Sums of Cell Count and Gut Area
cellcount_area_SUM = sum(cellcount_area);
gut_area_SUM = sum(gut_area);

% Append sums to the end of the results arrays.
cellcount_area_wSum = [cellcount_area cellcount_area_SUM];
gut_area_wSum = [gut_area gut_area_SUM];

% Transpose the data array into columns to align with list of file names. 
cellcount_area_wSum_column = cellcount_area_wSum'; 
gut_area_wSum_columm = gut_area_wSum';


%% Write Results to Output.xls File

% Create a matrix with cell count (Column 1)and gut area (Column 2).
Results = [cellcount_area_wSum_column, gut_area_wSum_columm];

% Write to .xls file. 
xlswrite('Output.xls', Results, 1, 'A1')
