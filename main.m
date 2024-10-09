% clear all
% close all
% clc
% 

for i = 1:50000
    dispGameOver = false;
    drawStep = 500;
    a = ChineseChessEngine(dispGameOver, drawStep);
    step = 0;
    while (~a.isOver && step < drawStep)
        allMoves = a.generateAllPossibleMoves();
        n = randi([1 size(allMoves,1)]);
        a = a.move(allMoves(n,1), allMoves(n,2:3));
        step = step + 1;
    end
    
    clear a;
    close all;
    clear all;
    clc;
end

% a = ChineseChessEngine();
% for i = 1:length(m)-1
%     a = a.move(m(i,1), m(i,2:3));
%     pause(1);
% end

