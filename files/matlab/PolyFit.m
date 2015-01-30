function [ a, y_polyo ] = PolyFit( x, y, o )
% fits an oth order polynomial to datapoints
% returns coefficients of fitted polynomial,
% returns polynomial values at x
n = length(x);

% xn is a matrix of values
% each column is a vector x.^n
% the first column is x
% the second column is x.^2
% and so on, until the 2*oth column: x.^(2*o)
xn = ones(n,2*o);

% sumxn is a vector of values
% each value in the vector is the sum of a column of matrix xn
% the first value is the sum of x
% the second value is the sum of x.^2
% and so on, until the 2*oth value: sum of x.^(2*o)
sumxn = 1:2*o;

% first column is x
xn(:,1) = x;

% first value is sum of x
sumxn(1) = sum(x);

% calculate the remaining columns and sums
for i=2:2*o
    % values of ith column in xn (i>1)
    xi = x.^i;
    % sum of values in ith column
    sumxn(i) = sum(xi); 
    % insert calculated values into ith column of xn
    xn(:,i) = xi;
end

% xny is a matrix of values
% each column is a vector (x.^n).*y
% first column is x.*y
% second column is (x.^2).*y
% and so on, until the oth column: (x.^o).*y
xny = ones(n,o);

% sumxny is a vector of values
% each value is the sum of a column of matrix xny
% the first value is the sum of x.*y
% the second value is the sum of (x.^2).*y
% and so on, until the oth value: sum of (x.^o).*y
sumxny = 1:o;

% calculate
for i=1:o
    % ith column of xny
    xniyi = xn(:,i).*y.';
    % insert calculated values into ith column of xny
    xny(:,i) = xniyi;
    % calculate sum of ith column of xny
    sumxny(i) = sum(xniyi);
end

% create coefficient matrix A using sums of vectors x.^n
A = ones(o+1);
A(1,1) = n;
A(1,2:o+1) = sumxn(1:o);
for i=2:o+1
    A(i,:) = sumxn(i-1:i-1+o);
end

% create solution vector using sums of vectors (x.^n).*y
b = ones(1,o+1);
b(1) = sum(y);
b(2:o+1) = sumxny(1:o);

% use inverse of A to find regression coefficients a
a = A\b.';

% use regression coefficients to calculate poly fit approximation
y_polyo = a(1).*ones(n,1);
for i=1:o
    y_polyo = y_polyo + a(i+1).*xn(:,i);
end

end