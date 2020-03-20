function [BW,maskedImage] = segmentImageAdaptiveThreshold(X)


% Threshold image - adaptive threshold
BW = imbinarize(X, 'adaptive', 'Sensitivity', 0.340000, 'ForegroundPolarity', 'bright');

% Create masked image.
maskedImage = X;
maskedImage(~BW) = 0;
end

