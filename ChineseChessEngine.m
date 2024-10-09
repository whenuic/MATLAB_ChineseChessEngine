classdef ChineseChessEngine < handle
    %CHINESECHESSENGINE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nCol = 9;
        nRow = 10;
        boardFigHandle;
        boardAxHandle;
        redPlayer;
        blackPlayer;
        next; % 1 or 2
        historyMoves; % [enumValue, newX, newY]
        pieces; % 1*32 Piece
        boardMatrix; % 10-by-9 matrix, every element is 0 or enumValue;
        isOver = false;
        
        isFirstClick = false;
        selectedPieceEnum;
        dispGameOver; % true, disp msgbox, false, don't disp msgbox
        drawStep; % after this number of moves, the game will end with draw
        
    end
    
    methods
        function this = ChineseChessEngine(dispGameOver, drawStep)
            this.historyMoves = [];
            this.next = 1;
            this.dispGameOver = dispGameOver;
            this.drawStep = drawStep;
            [this.boardFigHandle, this.boardAxHandle] = initializeBoard(this, this.nRow, this.nCol);
            this.pieces = initializePieces(this.boardAxHandle);
            this.boardMatrix = initializeMatrix(this.pieces, this.nRow, this.nCol);
        end
        
        function this = setSelectedPiece(this, enum)
            this.selectedPieceEnum = enum;
        end
        
        function this = move(this, enumValue, newPos)
            dispMsg = true;
            if this.pieces(enumValue).color == this.next && this.pieces(enumValue).isLive
                if isValidMove(this, enumValue, newPos, dispMsg)
                    % update next, update matrix, update piece, update
                    % display
                    if this.next == 1
                        this.next = 2;
                    elseif this.next == 2
                        this.next = 1;
                    end
                    
                    if this.boardMatrix(newPos(1), newPos(2)) ~= 0
                        pIdx = this.boardMatrix(newPos(1), newPos(2));
                        this.pieces(pIdx).setDead();
                    end
                    
                    this.boardMatrix(newPos(1), newPos(2)) = enumValue;
                    this.boardMatrix(this.pieces(enumValue).pos(1), this.pieces(enumValue).pos(2)) = 0;
                    
                    this.pieces(enumValue).setPos(newPos);
                    
                    this.historyMoves(end+1, :) = [enumValue, newPos(1), newPos(2)];
                    
                    if isGameOver(this) && this.dispGameOver
                        msgbox('Game Over!', 'game over');
                    end
                else
                    msgbox('Invalid move.', 'this.move');
                end
            else
                msgbox('Not this color or the piece is dead.', 'Invalid move');
            end            
        end
        
        function allPossibleMoves = generateAllPossibleMoves(this)
            dispMsg = false;
            allPossibleMoves = [];
            if this.next == 1
                startIdx = 1; endIdx = 16;
            elseif this.next == 2
                startIdx = 17; endIdx = 32;
            end
            for i = startIdx:endIdx
                if this.pieces(i).isLive
                    possibleMoves = this.pieces(i).getPossibleMoves();
                    for j = 1:size(possibleMoves,1)
                        if isValidMove(this, i, possibleMoves(j,:), dispMsg)
                            allPossibleMoves(end+1,:) = [i possibleMoves(j, :)];
                        end
                    end
                end
            end
        end
        
        function boolResult = isGameOver(this)
            boolResult = true;
            dispMsg = false;
            if this.next == 1
                startIdx = 1; endIdx = 16;
            elseif this.next == 2
                startIdx = 17; endIdx = 32;
            end
            for i = startIdx:endIdx
                if this.pieces(i).isLive
                    possibleMoves = this.pieces(i).getPossibleMoves();
                    for j = 1:size(possibleMoves,1)
                        if isValidMove(this, i, possibleMoves(j,:), dispMsg)
                            boolResult = false;
                            return
                        end
                    end
                end
            end
            this.isOver = true;
            if this.next == 1 % red lose, red has no where to move
                this.historyMoves(end+1,:) = [0 0 2]; % black win
            elseif this.next == 2 % black lose
                this.historyMoves(end+1,:) = [0 0 1]; % red win
            end
        end
        
        function delete(this)
            if size(this.historyMoves, 1) > 0 && this.isOver
                fileName = datestr(now,'yyyy_mm_dd_HH_MM_SS_FFF');
                if this.next == 1
                    whoWin = 'blackWin';
                elseif this.next ==2
                    whoWin = 'redWin';
                end
                fileName = [whoWin '_' fileName];
                fid = fopen([fileName '.txt'], 'wt');
                for i = 1:size(this.historyMoves, 1)
                    fprintf(fid, '%g\t',this.historyMoves(i,:));
                    fprintf(fid, '\n');
                end
                fclose(fid);
            end
            close(this.boardFigHandle);
        end
    end    
end

function boolResult = isValidMove(this, enumValue, newPos, dispMsg)
    boolResult = false;    
    piece = this.pieces(enumValue);
    matrix = this.boardMatrix;
    % can reach
    if newPos(1)<1||newPos(1)>9||newPos(2)<1||newPos(2)>10
        return;
    end
    if piece.canReach(newPos, matrix)
        matrix(newPos(1), newPos(2)) = piece.enumValue;
        matrix(piece.pos(1), piece.pos(2)) = 0;
        
        % if any opponent piece can reach my king?
        if this.next == 1
            if enumValue == 1
                myKingPos = newPos;
            else
                myKingPos = this.pieces(1).pos;
            end
            oppKingPos = this.pieces(17).pos;
            for val = 22:32
                if this.pieces(val).isLive && norm(this.pieces(val).pos - newPos) ~= 0
                    if this.pieces(val).canReach(myKingPos, matrix)
                        if dispMsg
                            msgbox('Invalid move.', 'KingChecked');
                        end
                        return
                    end
                end
            end
            if areKingsMet(myKingPos, oppKingPos, matrix)
                return
            end
            boolResult = true;
        elseif this.next == 2
            if enumValue == 17
                myKingPos = newPos;
            else
                myKingPos = this.pieces(17).pos;
            end
            oppKingPos = this.pieces(1).pos;
            for val = 6:16
                if this.pieces(val).isLive && norm(this.pieces(val).pos - newPos) ~= 0
                    if this.pieces(val).canReach(myKingPos, matrix)
                        if dispMsg
                            msgbox('Invalid move.', 'KingChecked');
                        end
                        return
                    end
                end
            end
            if areKingsMet(myKingPos, oppKingPos, matrix)
                return
            end
            boolResult = true;
        end
    end
end

function boolResult = areKingsMet(myKingPos, oppKingPos, matrix)
    boolResult = false;
    myKingX = myKingPos(1);
    count = 0;
    if myKingX == oppKingPos(1)
        if myKingPos(2) > oppKingPos(2)
            step = -1;
        else
            step = 1;
        end
        for y = myKingPos(2):step:oppKingPos(2)
            if matrix(myKingX, y) ~= 0
                count = count + 1;
            end
        end
        if count == 2
            boolResult = true;
        end
    end
end

function matrix = initializeMatrix(pieces,nRow,nCol)
    matrix = zeros(nCol, nRow);
    for i = 1:length(pieces)
        matrix(pieces(i).pos(1), pieces(i).pos(2)) = pieces(i).enumValue;
    end
end

function pieces = initializePieces(ax)
    pieces(1) = Piece(1, [5 1], 1, ax);
    pieces(2) = Piece(1, [4 1], 2, ax);
    pieces(3) = Piece(1, [6 1], 3, ax);
    pieces(4) = Piece(1, [3 1], 4, ax);
    pieces(5) = Piece(1, [7 1], 5, ax);
    pieces(6) = Piece(1, [2 1], 6, ax);
    pieces(7) = Piece(1, [8 1], 7, ax);
    pieces(8) = Piece(1, [1 1], 8, ax);
    pieces(9) = Piece(1, [9 1], 9, ax);
    pieces(10) = Piece(1, [2 3], 10, ax);
    pieces(11) = Piece(1, [8 3], 11, ax);
    pieces(12) = Piece(1, [1 4], 12, ax);
    pieces(13) = Piece(1, [3 4], 13, ax);
    pieces(14) = Piece(1, [5 4], 14, ax);
    pieces(15) = Piece(1, [7 4], 15, ax);
    pieces(16) = Piece(1, [9 4], 16, ax);
    pieces(17) = Piece(2, [5 10], 17, ax);
    pieces(18) = Piece(2, [4 10], 18, ax);
    pieces(19) = Piece(2, [6 10], 19, ax);
    pieces(20) = Piece(2, [3 10], 20, ax);
    pieces(21) = Piece(2, [7 10], 21, ax);
    pieces(22) = Piece(2, [2 10], 22, ax);
    pieces(23) = Piece(2, [8 10], 23, ax);
    pieces(24) = Piece(2, [1 10], 24, ax);
    pieces(25) = Piece(2, [9 10], 25, ax);
    pieces(26) = Piece(2, [2 8], 26, ax);
    pieces(27) = Piece(2, [8 8], 27, ax);
    pieces(28) = Piece(2, [1 7], 28, ax);
    pieces(29) = Piece(2, [3 7], 29, ax);
    pieces(30) = Piece(2, [5 7], 30, ax);
    pieces(31) = Piece(2, [7 7], 31, ax);
    pieces(32) = Piece(2, [9 7], 32, ax);
end

function [figH, axH] = initializeBoard(this, nRow, nCol)
    figH = figure;
    set(figH, 'name', 'ChineseChess', 'menubar', 'none', 'toolbar', 'none', 'WindowButtonDownFcn', {@winButtonDown, this});
    figH.Position = [1200 100 580 630];
    axH = axes(figH);
    box off;
    hold on;
    axis equal;
    drawBoard(axH, nRow, nCol);
end

function winButtonDown(src, event, this)
    pt = get(gca, 'CurrentPoint');
    x = round(pt(1,1));
    y = round(pt(1,2));
    if x > 9 || x < 1 || y > 10 || y < 1
        msgbox('Clicked position out of board.', 'Click error.');
        return
    end
    if ~this.isFirstClick
        this.isFirstClick = true;
        enum = this.boardMatrix(x, y);
        if (enum ~= 0)
            this.setSelectedPiece(enum);
        else
            msgbox('No piece at clicked position.', '1st Click invalid.');
        end
    else
        this.move(this.selectedPieceEnum, [x y]);
        this.isFirstClick = false;
    end
    
end

function drawBoard(ax, nRow, nCol)
    axis([0 nCol+1 0 nRow+1]);
    xticks(1:9);
    yticks(1:10);
    % plot horizontal lines
    for i = 1:nRow
        plot(ax, [1, nCol], [i, i], 'k-');
    end
    % plot vertical lines
    for i = 1:nCol
        plot(ax, [i, i], [1, nRow/2], 'k-');
        plot(ax, [i, i], [nRow/2+1 nRow], 'k-');
    end
    plot(ax, [1, 1], [nRow/2, nRow/2+1], 'k-');
    plot(ax, [nCol, nCol], [nRow/2, nRow/2+1], 'k-');
    % plot diagnal lines
    plot(ax, [(nCol-1)/2, (nCol+1)/2+1], [1, 3], 'k-');
    plot(ax, [(nCol-1)/2, (nCol+1)/2+1], [nRow-2, nRow], 'k-');
    plot(ax, [(nCol-1)/2, (nCol+1)/2+1], [3, 1], 'k-');
    plot(ax, [(nCol-1)/2, (nCol+1)/2+1], [nRow, nRow-2], 'k-');
    
    % plot pao init pos cross
    xPos = [2 3 5 7 8 2 3 5 7 8 1 1 9 9];
    yPos = [3 4 4 4 3 8 7 7 7 8 4 7 4 7];
    for i = 1:length(xPos)
        if xPos(i) == 1
            drawL(ax, xPos(i), yPos(i), 1);
            drawL(ax, xPos(i), yPos(i), 4);
        elseif xPos(i) == nCol
            drawL(ax, xPos(i), yPos(i), 2);
            drawL(ax, xPos(i), yPos(i), 3);
        else
            for j = 1:4
                drawL(ax, xPos(i), yPos(i), j);
            end
        end
    end
end

function drawL(ax, x, y, r)
    c1 = 0.05;
    c2 = 0.15;
    switch r
        case 1
            k1 = 1;
            k2 = 1;
        case 2
            k1 = -1;
            k2 = 1;
        case 3
            k1 = -1;
            k2 = -1;
        case 4
            k1 = 1;
            k2 = -1;
    end    
    x1 = x+k1*c1;
    x2 = x+k1*c2;
    y1 = y+k2*c1;
    y2 = y+k2*c2;
    plot(ax, [x1 x2], [y1 y1], 'k-');
    plot(ax, [x1 x1], [y1 y2], 'k-');
end