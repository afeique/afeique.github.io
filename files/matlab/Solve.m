function [ x ] = Solve( A, y )
%Solves a system of equations [A]{x} = [y]
    
    [h, w] = size(A);
    if (w ~= h)
        error('Matrix not square.');
    end
    
    d = w;
    [h, w] = size(y);
    if (h ~= d || w ~= 1)
        error('Vector is wrong dimension.');
    end
    
    [L, U] = Crout(A);
    z = ForwardSub(L, y);
    x = BackSub(U, z);
end

