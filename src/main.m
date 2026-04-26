clear;
clc;
close all;

dicomFolder = uigetdir(pwd, 'Select DICOM slice folder');
if isequal(dicomFolder, 0)
    error('No DICOM folder selected.');
end

volume = dicom.loadDicomSliceVolume(dicomFolder, ...
    Recursive = true, ...
    ApplyRescale = true, ...
    Verbose = true);

disp(volume);

V = volume.Data;
middleSlice = round(volume.numSlices() / 2);

figure;
imagesc(V(:, :, middleSlice));
axis image;
colormap gray;
colorbar;
title(sprintf('Middle slice %d / %d', middleSlice, volume.numSlices()));

viz.showOrthogonalViews(volume)

% In Hounsfield units, -500 is at the lung level
viz.showIsosurface(volume, -500, ...
    Resolution = "preview", ...
    ReduceMesh = false);
