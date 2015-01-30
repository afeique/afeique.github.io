function [ L, U ] = Crout( A )
% Uses Crout method to decompose a matrix into lower and upper triangular matrices

% performs crout decomposition on matrix A and returns
% lower-triangular and upper-triangular matrices
    [h, w] = size(A);
    if (w > h)
        error('Too many unknowns.');
    end
    if (w ~= h)
        error('Matrix not square.');
    end

    d = w;
    
    if (d == 1)
        error('Scalar.');
    end
    
    L = zeros(d,d);
    U = zeros(d,d);
    for i=1:d
        L(i,1) = A(i,1);
        U(i,i) = 1;
    end
    for j=2:d
        U(1,j) = A(1,j)/L(1,1);
    end
    
    for i=2:d
        for j=2:d
            sum = 0;
            for n=1:j-1
                sum = sum + L(i,n)*U(n,j);
            end
            if (j <= i)
                L(i,j) = A(i,j) - sum;
            else
                if (L(i,i) ~= 0)
                    U(i,j) = (A(i,j) - sum)/L(i,i);
                else
                    U(i,j) = 0;
                end
            end
        end
    end
end

