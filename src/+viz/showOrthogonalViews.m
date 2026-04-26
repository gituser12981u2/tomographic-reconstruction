function showOrthogonalViews(volume)
%SHOWORTHOGONALVIEWS Display axial, coronal, and sagittal center slices.

V = volume.Data;

row = round(volume.rows() / 2);
col = round(volume.cols() / 2);
sliceIndex = round(volume.numSlices() / 2);

figure;

subplot(1,3,1);
imagesc(V(:,:,sliceIndex));
axis image off;
colormap gray;
title(sprintf('Axial k=%d', sliceIndex));

subplot(1,3,2);
imagesc(squeeze(V(row,:,:))');
axis image off;
colormap gray;
title(sprintf('Coronal row=%d', row));

subplot(1,3,3);
imagesc(squeeze(V(:,col,:))');
axis image off;
colormap gray;
title(sprintf('Sagitall col=%d', col));
end








