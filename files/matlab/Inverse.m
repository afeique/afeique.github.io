function [ Ai ] = Inverse( A )
% computes matrix inverse of A by solving system
% uses Crout decomposition, forward-substitution, and back-substitution

    [h, w] = size(A);
    if (w ~= h)
        error('Matrix not square.');
    end
    
    d = w;
    Ai = zeros(d,d);
    [L, U] = Crout(A);
    N = zeros(d,d);
    I = eye(d);
    for j=1:d
        N(:,j) = ForwardSub(L, I(:,j));
    end
    for j=1:d
        Ai(:,j) = BackSub(U, N(:,j));
    end
end

