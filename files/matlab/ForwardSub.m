function [ z ] = ForwardSub( L, b )
% Solves system of lower-triangular matrix and vector using back-substitution
 
    [h, w] = size(L);
    if (w ~= h)
        error('Matrix not square.');
    end

    d = w;
    
    if (d == 1)
        error('Scalar.');
    end
    
    isLower = 1;
    for i=1:d
        for j=i+1:d
            if (L(i,j) ~= 0)
                isLower = 0;
                break;
            end
        end
    end
    if (~isLower)
        error('Not lower triangular.');
    end
    
    [~, w] = size(b);
    if (w ~= 1)
        b = b.';
    end
    [h, w] = size(b);
    if (h ~= d || w ~= 1)
        error('Vector is wrong dimension.');
    end
    
    z = zeros(d,1);
    z(1) = b(1) / L(1,1);
    for i=2:d
        sum = 0;
        for n=1:i-1
            sum = sum + L(i,n)*z(n);
        end
        z(i) = (b(i) - sum)/L(i,i);
    end
end

