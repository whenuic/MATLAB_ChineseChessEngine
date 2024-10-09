e = Engine();
matrix = zeros(9, 10);
matrix(:,1) = [8 6 4 2 1 3 5 7 9];
matrix(:,10) = [8 6 4 2 1 3 5 7 9]+16;
matrix(2, 3) = 10; matrix(8, 3) = 11;
matrix(2, 8) = 26; matrix(8, 8) = 27;
matrix(:, 4) = [12 0 13 0 14 0 15 0 16];
matrix(:, 7) = [28 0 29 0 30 0 31 0 32];
pos = zeros(32,2);
for i = 1:9
    for j = 1:10
        if matrix(i,j)>0
            pos(matrix(i,j),:) = [i j];
        end
    end
end

next = 1;
result = -1; % -1 : open; 0 : draw; 1 : redwin; 2 : blackwin
initStatus = struct('matrix', matrix, 'position', pos, 'next', next, 'result', result);

s = initStatus;

n = 4000000;
T = repmat(s, [1 n]);