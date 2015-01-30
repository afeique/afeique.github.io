function [ a_0, a_1 ] = LinReg( x, y )
% calculates the coefficients of linear regression

x2 = x.^2;
y2 = y.^2;
xy = x.*y;
n = length(x);
sum_x = sum(x);
sum_y = sum(y);
sum_x2 = sum(x2);
%sum_y2 = sum(y2);
sum_xy = sum(xy);
avg_x = sum_x/n;
avg_y = sum_y/n;

a_1 = (n*sum_xy - sum_x*sum_y)/(n*sum_x2 - sum_x^2);
a_0 = avg_y - avg_x*a_1;

end

