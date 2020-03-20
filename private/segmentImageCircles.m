function [BW,maskedImage,centers,radii] = segmentImageCircles(X,sensitivity,maxRad,minRad,maxN)
%segmentImage Segment Circles in image 
%  [BW,maskedImage,centers,radii] = segmentImageCircles(X,sensitivity,maxRad,minRad,maxN) segments image X using auto-generated
%




% Find circles
[centers,radii,~] = imfindcircles(X,[minRad maxRad],'ObjectPolarity','bright','Sensitivity',sensitivity);
BW = false(size(X,1),size(X,2));
[Xgrid,Ygrid] = meshgrid(1:size(BW,2),1:size(BW,1));
for n = 1:maxN
    BW = BW | (hypot(Xgrid-centers(n,1),Ygrid-centers(n,2)) <= radii(n));
end

% Create masked image.
maskedImage = X;
maskedImage(~BW) = 0;
end

