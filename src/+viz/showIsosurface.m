function showIsosurface(volume, isovalue, options)
%SHOWISOSURFACE Display an isosurface from a uniform z volume.
%
%   showIsosurface(volume, isovalue)
%   showIsosurface(volume, isovalue, Resolution="preview")
%   showIsosurface(volume, isovalue, Resolution="full")
%
%   Options:
%       Resolution      "preview" or "full"
%       DownsampleStep  integer step used for preview mode
%       Smooth          true/false
%       SmoothSize      smoothing kernel size
%       ReduceMesh      true/false
%       ReduceRatio     fraction of faces to keep, e.g. 0.25
%
%   Example:
%       showIsosurface(volume, -500, Resolution="preview", DownsampleStep=6)
%       showIsosurface(volume, 300, Resolution="full", ReduceMesh=true)

arguments
    volume Volume
    isovalue (1,1) double
    options.Resolution (1,1) string {mustBeMember(options.Resolution, ["preview", "full"])} = "preview"
    options.DownsampleStep (1,1) double {mustBeInteger, mustBePositive} = 4
    options.Smooth (1,1) logical = false
    options.SmoothSize (1,1) double {mustBeInteger, mustBePositive} = 3
    options.ReduceMesh (1,1) logical = true
    options.ReduceRatio (1,1) double {mustBePositive, mustBeLessThanOrEqual(options.ReduceRatio, 1)} = 0.25
end

if ~volume.hasUniformZ()
    error('showIsosurface:NonuniformZ', ...
        'Isosurface expects uniform z spacing.');
end

switch options.Resolution
    case "preview"
        step = options.DownsampleStep;
    case "full"
        step = 1;
end

V = volume.Data(1:step:end, 1:step:end, 1:step:end);

x = (0:step:volume.cols() - 1) * volume.dx();
y = (0:step:volume.rows() - 1) * volume.dy();
z = volume.ZPositions(1:step:end);

if options.Smooth > 1
    V = smooth3(V, 'box', options.SmoothSize);
end

fprintf('Generating isosurface...\n');
fprintf('  Resolution:      %s\n', options.Resolution);
fprintf('  Downsample step: %d\n', step);
fprintf('  Volume size:     [%d %d %d]\n', size(V,1), size(V,2), size(V,3));
fprintf('  Isovalue:         %.6g\n', isovalue);

fv = isosurface(x, y, z, V, isovalue);

if isempty(fv.vertices)
    error('showIsosurface:EmptySurface', ...
        'No isosurface was found at isovalue %.6g.', isovalue);
end

if options.ReduceMesh == true && options.ReduceRatio < 1
    fprintf('Reducing mesh to %.1f%% of faces...\n', 100 * options.ReduceRatio);
    fv = reducepatch(fv, options.ReduceRatio);
end

figure;
p = patch(fv);

isonormals(x, y, z, V, p);

p.FaceColor = [0.8 0.8 0.8];
p.EdgeColor = 'none';

daspect([1 1 1]);
view(3);
axis tight;
camlight;
lighting gouraud;

xlabel('x');
ylabel('y');
zlabel('z');
title(sprintf('Isosurface at %.3g (%s, step=%d)', ...
    isovalue, options.Resolution, step));

fprintf('Done.\n');
fprintf(' Vertices: %d\n', size(fv.vertices, 1));
fprintf(' Faces:    %d\n', size(fv.faces, 1));
end
