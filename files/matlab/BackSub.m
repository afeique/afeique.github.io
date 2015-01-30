function [ x ] = BackSub( U, z )
% Solves system of upper-triangular matrix and vector using back-substitution

    [h, w] = size(U);
    if (w ~= h)
        error('Matrix not square.');
    end

    d = w;
    
    if (d == 1)
        error('Scalar.');
    end
    
    isUpper = 1;
    for i=1:d
        for j=1:i-1
            if (U(i,j) ~= 0)
                isUpper = 0;
                break;
            end
        end
    end
    if (~isUpper)
        error('Not upper triangular.');
    end
    
    [~, w] = size(z);
    if (w ~= 1)
        b = b.';
    end
    [h, w] = size(z);
    if (h ~= d || w ~= 1)
        error('Vector is wrong dimension.');
    end
    
    x = zeros(d,1);
    x(d) = z(d) / U(d,d);
    for i=d-1:-1:1
        sum = 0;
        for n=d:-1:i
            sum = sum + U(i,n)*x(n);
        end
        
        x(i) = (z(i) - sum)/U(i,i);
    end
end

