e = Engine();
matrix = zeros(9, 10);
% matrix(:,1) = [8 6 4 2 1 3 5 7 9];
% matrix(:,10) = [8 6 4 2 1 3 5 7 9]+16;
% matrix(2, 3) = 10; matrix(8, 3) = 11;
% matrix(2, 8) = 26; matrix(8, 8) = 27;
% matrix(:, 4) = [12 0 13 0 14 0 15 0 16];
% matrix(:, 7) = [28 0 29 0 30 0 31 0 32];
% pos = [5 1; 4 1; 6 1; 3 1; 7 1; 2 1; 8 1; 1 1; 9 1;...
%        2 3; 8 3; 1 4; 3 4; 5 4; 7 4; 9 4;...
%        5 10; 4 10; 6 10; 3 10; 7 10; 2 10; 8 10; 1 10; 9 10;...
%        2 8; 8 8; 1 7; 3 7; 5 7; 7 7; 9 7];


matrix(5,1) = 1; matrix(6,1)=2; matrix(4,6)=10; matrix(4,9) = 6; matrix(2,10) = 8;
matrix(5,10)=17; matrix(4,10)=18; matrix(6,10)=19; matrix(5,8) = 20; matrix(7,10) = 21; matrix(8,7) = 22; matrix(1,3) = 24; matrix(4,2) = 32;
% pos = zeros(32,2); pos(1,:) = [5 1];pos(2,:) = [4 1];pos(3,:) = [5 2];
% pos(8,:) = [4 3];pos(9,:) = [2 4];pos(17,:) = [5 10];pos(18,:) = [4 10];
% pos(19,:) = [5 9];pos(22,:) = [4 8];

% matrix(4,2) = 1; matrix(5,2)=2; matrix(9,3)=4; matrix(2,3) = 10; matrix(3,5)=12;
% matrix(5,10)=17; matrix(5,9)=18; matrix(4,8)=19;matrix(3,10)=20;matrix(5,8)=21;
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
e.setBoard(s);
moves = e.getAllValidMoves();
size(moves,1)
numFwdMoves = 10;
[bestMove, idx, res] = chooseMove(e, s, moves, numFwdMoves);
function [bestMove, idx, res] = chooseMove(e, s, moves, numFwdMoves)
    res = zeros(size(moves,1), 3);
    next = s.next;
    for i = 1:size(moves,1)
        i
        t = tic;
        loopBound = 1;
        s1 = applyMove(s, moves(i,:));        
        rwin = zeros(loopBound, 1); bwin = zeros(loopBound, 1); draw = zeros(loopBound, 1);
        parfor j = 1:loopBound
            r = playTillEnd(s1, e, numFwdMoves);
            if r == 1
                rwin(j) = 1;
            elseif r == 2
                bwin(j) = 1;
            else
                draw(j) = 1;
            end
        end
        res(i, :) = [sum(rwin) sum(bwin) sum(draw)];
        toc(t)
    end
    if next == 1
        [~, idx] = max(res(:, 1));
    elseif next == 2
        [~, idx] = max(res(:, 2));
    end
    bestMove = moves(idx, :);
end