e = Engine();
matrix = zeros(9, 10);
matrix(:,1) = [8 6 4 2 1 3 5 7 9];
matrix(:,10) = [8 6 4 2 1 3 5 7 9]+16;
matrix(2, 3) = 10; matrix(8, 3) = 11;
matrix(2, 8) = 26; matrix(8, 8) = 27;
matrix(:, 4) = [12 0 13 0 14 0 15 0 16];
matrix(:, 7) = [28 0 29 0 30 0 31 0 32];

% matrix(5,1) = 1; matrix(5,2) = 2;
% matrix(5,10) = 17;
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
initStatus = struct('matrix', matrix, 'position', pos, 'next', next, 'result', result, 'firstChild', -1, 'nextSibling', -1);

s = initStatus;
T(4000000) = s;
T(1) = s;
level = 4;
currLevel = 2;
parentStart = 1;
parentEnd = 1;
t = tic;
endIdx = 1;
while(currLevel <= level)
    for i = parentStart:parentEnd
        p = T(i);
        e.setBoard(p);
        moves = e.getAllValidMoves();
        n = size(moves,1);
        if n == 0
            if T(i).next == 1
                T(i).result = 2;
            elseif T(i).next == 2
                T(i).result = 1;
            end
        end
        for j = 1:n
            endIdx = endIdx + 1;
            T(endIdx) = applyMove(p, moves(j,:));
            if j == 1
                T(i).firstChild = endIdx;
            else
                T(endIdx-1).nextSibling = endIdx;
            end
        end
    end
    if endIdx > parentEnd
        parentStart = parentEnd+1;
        parentEnd = endIdx;
    end
    currLevel = currLevel + 1;
end
toc(t);

function s = applyMove(s, m) % status and move
    newX = m(2); newY = m(3);
    val = m(1);
    currPos = s.position(val,:);
    currX = currPos(1); currY = currPos(2);
    newPosVal = s.matrix(newX, newY);
    if newPosVal == 0
        s.matrix(newX, newY) = val;
        s.matrix(currX, currY) = 0;
        s.position(val,:) = [newX newY];
    else
        s.position(newPosVal, :) = [0 0];
        s.matrix(newX, newY) = val;
        s.matrix(currX, currY) = 0;
        s.position(val, :) = [newX newY];
    end
    if s.next == 1
        s.next = 2;
    elseif s.next == 2
        s.next = 1;
    end
end
