function volume = loadDicomSliceVolume(folder, options)
%LOADDICOMSLICEVOLUME Load reconstructed CT DICOM slices into a Volume.
%
% Used for testing
%
% Reads DICOM image files from folder, extracts pixel data and geometry metadata,
% create Slice objects, and constructs a Volume.
%
% This is intended for reconstructed CT image slices, not raw projection
% DICOM-CT-PD files.

arguments
    folder (1, :) char
    options.Recursive (1,1) logical = true
    options.ApplyRescale (1,1) logical = true
    options.Verbose (1,1) logical = true
end

if ~isfolder(folder)
    error('loadDicomSliceVolume:InvalidFolder', ...
        'Folder does not exist: %s', folder);
end

if options.Recursive
    files = dir(fullfile(folder, '**', '*.dcm'));
else
    files = dir(fullfile(folder, '*.dcm'));
end

if isempty(files)
    error('loadDicomSliceVolume:NoDicomFiles', ...
        'No .dcm files found under: %s', folder);
end

if options.Verbose
    fprintf('Found %d .dcm files.\n', numel(files));
end

files = files(~[files.isdir]);
dummy = Slice(zeros(1,1), [1 1], 0);
slices = repmat(dummy, 1, numel(files));
numSlices = 0;

referenceOrientation = [];
referenceSeriesUID = "";

for k = 1:numel(files)
    path = fullfile(files(k).folder, files(k).name);

    try
        info = dicominfo(path);
    catch ME
        if options.Verbose
            fprintf('Skipping unreadable DICOM: %s\n  Reason: %s\n', path, ME.message);
        end
        continue;
    end

    if isfield(info, 'Modality') && ~strcmpi(string(info.Modality), "CT")
        if options.Verbose
            fprintf('Skipping non-CT file: %s\n', path);
        end
        continue;
    end

    if ~isfield(info, 'PixelSpacing')
        if options.Verbose
            fprintf('Skipping file without PixelSpacing: %s\n', path);
        end
        continue;
    end

    if ~isfield(info, 'ImagePositionPatient')
        if options.Verbose
            fprintf('Skipping file without ImagePositionPatient: %s\n', path);
        end
        continue;
    end

    if isfield(info, 'SeriesInstanceUID')
        seriesUID = string(info.SeriesInstanceUID);

        if referenceSeriesUID == ""
            referenceSeriesUID = seriesUID;
        elseif seriesUID ~= referenceSeriesUID
            continue;
        end
    end

    img = double(dicomread(info));

    if options.ApplyRescale
        if isfield(info, 'RescaleSlope')
            slope = double(info.RescaleSlope);
        else
            slope = 1.0;
        end

        if isfield(info, 'RescaleIntercept')
            intercept = double(info.RescaleIntercept);
        else
            intercept = 0.0;
        end

        img = slope .* img + intercept;
    end

    % DICOM pixel spacing is [rowSpacing; columnSpacing] = [dy; dx]
    dy = double(info.PixelSpacing(1));
    dx = double(info.PixelSpacing(2));
    spacingXY = [dx dy];

    ipp = double(info.ImagePositionPatient(:));

    if isfield(info, 'ImageOrientationPatient')
        orientation = double(info.ImageOrientationPatient(:));

        if isempty(referenceOrientation)
            referenceOrientation = orientation;
        elseif max(abs(orientation - referenceOrientation)) > 1e-6
            fprintf('Reference orientation:\n');
            disp(referenceOrientation.');

            fprintf('Current orientation:\n');
            disp(orientation.');

            fprintf('File:\n%s\n', path);
            error('loadDicomSliceVolume:MixedOrientation', ...
                'DICOM folder contains slices with inconsistent orientation.');
        end

        rowDir = orientation(1:3);
        colDir = orientation(4:6);
        normal = cross(rowDir, colDir);
        normal = normal ./ norm(normal);

        zPosition = dot(ipp, normal);

    else
        % Fallback for simpler axial stacks
        zPosition = ipp(3);
    end

    id = string(files(k).name);

    metadata = struct();
    metadata.Filename = string(path);

    if isfield(info, 'SOPInstanceUID')
        metadata.SOPInstanceUID = string(info.SOPInstanceUID);
    end

    if isfield(info, 'SeriesInstanceUID')
        metadata.SeriesInstanceUID = string(info.SeriesInstanceUID);
    end

    if isfield(info, 'InstanceNumber')
        metadata.SliceThickness = double(info.SliceThickness);
    end

    metadata.ImagePositionPatient = ipp;
    metadata.PixelSpacing = double(info.PixelSpacing(:));

    numSlices = numSlices + 1;
    slices(numSlices) = Slice(img, spacingXY, zPosition, ...
        OriginXY = [0 0], ...
        ID = id, ...
        Metadata = metadata);
end

slices = slices(1:numSlices);
slices = slices(:);

if isempty(slices)
    error('loadDicomSliceVolume:NoSlicesFound', ...
        'No usable reconstructed DICOM slices were found in: %s', folder);
end

volume = Volume(slices);
end
