classdef Engine < handle
    %ENGINE Summary of this class goes here
    % The engine only takes an input of board status(struct of board 
    % matrix, who's at where, who's next) and generates all valid moves.
    % The input board status could also be a node in the search tree.
    % It also answers other queries.
    
    properties
        matrix; % 9-by-10 matrix. 1-32 means what pieces, 0-no piece
        position; % 32-by-2 matrix. ith row [0 0]: ith piece not on board
        next; % 1-red; 2-black
        result; % 1-red win; 2-black win; 0-draw; -1-open      
    end
    
    methods
        function this = Engine()
        end
        
        function this = setBoard(this, status)
            this.matrix = status.matrix;
            this.position = status.position;
            this.next = status.next;
            this.result = status.result;
        end
        
        function boolResult = hasValidMove(this)
            if this.next == 1
                startIdx = 1; endIdx = 16;
            elseif this.next == 2
                startIdx = 17; endIdx = 32;
            end
            for i = startIdx:endIdx
                if ~isequal(this.position(i, :), [0 0])
                    if this.hasPieceValidMove(i)
                        boolResult = true;
                        return;
                    end
                end
            end
            boolResult = false;
        end
        
        function moves = getAllValidMoves(this)
            moves = [];
            if this.next == 1
                pool = 1:16;
            elseif this.next == 2
                pool = 17:32;
            end
            notConsiderIdx = [];            
            if isSymmetric(this.matrix)
                for i = 1:length(pool)
                    pos = this.position(i,:);
                    if isequal(pos, [0 0]) || pos(1) > 5
                        notConsiderIdx(end+1) = i;
                    end                        
                end
            end
            pool(notConsiderIdx) = [];
                
            for i = 1:length(pool)
                if ~isequal(this.position(pool(i), :), [0 0])
                    moves = [moves; this.getPieceValidMoves(pool(i))];
                end
            end
        end
        
        function boolResult = hasPieceValidMove(this, val)
            % apply template moves
            moves = getPieceTemplateMoves(this.position(val, :), val);            
            for i = size(moves,1):-1:1
                if isValidMove(this, val, moves(i,:))
                    boolResult = true;
                    return;
                end
            end
            boolResult = false;
        end
        
        function validMoves = getPieceValidMoves(this, val)
            % apply template moves
            moves = getPieceTemplateMoves(this.position(val, :), val);
            
            % drop invalid moves from template moves
            for i = size(moves,1):-1:1
                if ~isValidMove(this, val, moves(i,:))
                    moves(i,:) = [];
                end
            end
            
            % attach [val move]
            validMoves = [val*ones(size(moves,1),1) moves];
        end
        
        function boolResult = isValidMove(this, val, newPos)
            boolResult = false;
            % can reach?
            if ~canReach(this.position(val, :), newPos, this.matrix, val)
                return;
            end
            % can opponent reach my king?
            newMatrix = this.matrix;
            newPosition = this.position;
            valAtNewPos = newMatrix(newPos(1), newPos(2));
            currPos = this.position(val, :);
            if valAtNewPos ~= 0
                newPosition(valAtNewPos, :) = [0 0];
            end
            newPosition(val,:) = newPos;
            newMatrix(newPos(1), newPos(2)) = val;
            newMatrix(currPos(1), currPos(2)) = 0;
            
            if isKingChecked(getColor(val), newMatrix, newPosition)
                return
            end
            boolResult = true;
        end
    end
end

function boolResult = isKingChecked(myColor, matrix, position)
    boolResult = true;
    if myColor == 1
        myKingPos = position(1,:);
        oppKingPos = position(17, :);
        startIdx = 22;
        endIdx = 32;
    elseif myColor == 2
        myKingPos = position(17,:);
        oppKingPos = position(1, :);
        startIdx = 6;
        endIdx = 16;
    end
    for val = startIdx:endIdx
        if ~isequal(position(val,:), [0 0])
            if canReach(position(val,:), myKingPos, matrix, val)
                return
            end
        end
    end
    if areKingsMet(myKingPos, oppKingPos, matrix)
        return
    end
    boolResult = false;
end

function boolResult = areKingsMet(myKingPos, oppKingPos, matrix)
    boolResult = false;
    if myKingPos(1) == oppKingPos(1)
        for y = min(myKingPos(2), oppKingPos(2))+1:max(myKingPos(2), oppKingPos(2))-1
            if matrix(myKingPos(1), y) ~= 0
                return
            end
        end
        boolResult = true;
    end
end

function boolResult = canReach(currPos, newPos, matrix, val)
    newX = newPos(1);
    newY = newPos(2);
    currX = currPos(1);
    currY = currPos(2);
    if newX<1 || newX>9 || newY<1 || newY >10
        boolResult = false;
        return;
    end
    newPosVal = matrix(newX, newY);
    if isequal(currPos, newPos) % Stayed at the curr pos...
        boolResult = false;
        return;
    end   
    if (val<=16 && newPosVal<=16 && newPosVal>=1) ... % has own piece at newPos
            || (val>16 && newPosVal<=32 && newPosVal>=17)
        boolResult = false;
        return
    end
    if  val == 1 || val == 17 % King
        boolResult = canReachKing(getColor(val), newX, newY, currX, currY);
    elseif val == 2 || val == 3 || val == 18 || val == 19 % Guard
        boolResult = canReachGuard(getColor(val), newX, newY, currX, currY);
    elseif val == 4 || val == 5 || val == 20 || val == 21 % Bishop
        boolResult = canReachBishop(getColor(val), newX, newY, currX, currY, matrix);
    elseif val == 6 || val == 7 || val == 22 || val == 23 % Knight
        boolResult = canReachKnight(newX, newY, currX, currY, matrix);
    elseif val == 8 || val == 9 || val == 24 || val == 25 % Rook
        boolResult = canReachRook(newX, newY, currX, currY, matrix);
    elseif val == 10 || val == 11 || val == 26 || val == 27 % Cannon
        boolResult = canReachCannon(newX, newY, currX, currY, matrix);
    else % Pawn
        boolResult = canReachPawn(getColor(val), newX, newY, currX, currY);
    end
end

function moves = getPieceTemplateMoves(currPos, val)
    if  val == 1 || val == 17 % King
        moves = currPos + [1 0; 0 1; -1 0; 0 -1];
    elseif val == 2 || val == 3 || val == 18 || val == 19 % Guard
        moves = currPos + [1 1; -1 1; -1 -1; 1 -1];
    elseif val == 4 || val == 5 || val == 20 || val == 21 % Bishop
        moves = currPos + [2 2; -2 2; -2 -2; 2 -2];
    elseif val == 6 || val == 7 || val == 22 || val == 23 % Knight
        moves = currPos + [2 1;1 2;-1 2;-2 1;-2 -1;-1 -2;1 -2;2 -1];
    elseif val == 8 || val == 9 || val == 24 || val == 25 ||... % Rook
            val == 10 || val == 11 || val == 26 || val == 27 % Cannon
        x = currPos(1); y = currPos(2);
        for i = 1:10
            moves(i, :) = [x i];
        end
        moves(y, :) = [];
        for i = 1:9
            moves(end+1, :) = [i y];
        end
        moves(x+9, :) = [];
    else % Pawn
        moves = currPos + [1 0; -1 0; 0 1; 0 -1];
    end
end

function color = getColor(val)
%     if val<17
%         color = 1;
%     else
%         color = 2;
%     end
    color = ceil(val/16); % this is better than if else.
end

function boolResult = canReachKing(color, newX, newY, currX, currY)
    boolResult = false;
    if abs(newX-currX) + abs(newY-currY) ~= 1
        return
    end
    if (color == 1 && withinRange([newX newY], 4,6,1,3)) ...
            || (color == 2 && withinRange([newX newY], 4,6,8,10))
            boolResult = true;
    end
end

function boolResult = canReachGuard(color, newX, newY, currX, currY)
    boolResult = false;
    if abs(newX-currX) + abs(newY-currY) ~= 2
        return
    end
    if (color == 1 && withinRange([newX newY], 4,6,1,3)) ...
            || (color == 2 && withinRange([newX newY], 4,6,8,10))
        boolResult = true;
    end
end

function boolResult = canReachBishop(color, newX, newY, currX, currY, matrix)
    boolResult = false;
    if (abs(newX-currX)~=2 || abs(newY-currY)~=2) ...
            || matrix((newX+currX)/2, (newY+currY)/2)~=0
        return
    end
    if (color == 1 && withinRange([newX newY], 1, 9, 1, 5)) ...
            || (color == 2 && withinRange([newX newY], 1, 9, 6, 10))
            boolResult = true;
    end
end

function boolResult = canReachRook(newX, newY, currX, currY, matrix)
    boolResult = false;
    if (newX ~= currX && newY ~= currY) || ~withinRange([newX newY], 1,9,1,10)
        return;
    end
    if ~hasPieceBetween([currX currY], [newX newY], matrix)
        boolResult = true;
    end        
end

function boolResult = canReachKnight(newX, newY, currX, currY, matrix)
    boolResult = false;
    diffX = abs(newX-currX);
    diffY = abs(newY-currY);
    if ~((diffX==1 && diffY==2)||(diffX==2 && diffY==1)) || ~withinRange([newX newY], 1, 9, 1, 10)
        return
    end
    stepX = newX-currX;
    stepY = newY-currY;
    if abs(stepX) == 2
        if matrix(currX+stepX/2, currY) == 0
            boolResult = true;
        end
    end
    if abs(stepY) == 2
        if matrix(currX, currY+stepY/2)==0
            boolResult = true;
        end
    end 
end

function boolResult = canReachCannon(newX, newY, currX, currY, matrix)
    boolResult = false;
    if (newX ~= currX && newY ~= currY) || ~withinRange([newX newY], 1,9,1,10)
        return
    end
    if matrix(newX, newY) == 0
        boolResult = ~hasPieceBetween([currX currY], [newX newY], matrix);
    else
        normDiffVec = max(abs(newX-currX), abs(newY-currY));
        diffVec = [newX newY]-[currX currY];        
        stepVec = diffVec/normDiffVec;
        if normDiffVec <= 1
            return
        end
        countInMiddle = 0;
        for i = 1:normDiffVec-1
            if hasPiece([currX currY]+stepVec*i, matrix)
                countInMiddle = countInMiddle + 1;
            end
        end
        if countInMiddle == 1
            boolResult = true;
        end
    end
end

function boolResult = canReachPawn(color, newX, newY, currX, currY)
    boolResult = false;
    if (abs(newX-currX)+abs(newY-currY)) ~= 1 || ~withinRange([newX newY], 1, 9, 1, 10)
        return
    end
    if color == 1
        if ((currY == 4 || currY == 5) && newY <= currY) || (currY >= 6 && newY < currY)
            return
        else
            boolResult = true;
        end            
    elseif color == 2
        if ((currY == 7 || currY == 6) && newY >= currY) || (currY <= 5 && newY > currY)
            return
        else
            boolResult = true;
        end
    end
end

function boolResult = withinRange(pos, xmin, xmax, ymin, ymax)
    if pos(1) <= xmax && pos(1) >= xmin && pos(2) <= ymax && pos(2) >= ymin
        boolResult = true;
    else
        boolResult = false;
    end
end

function boolResult = hasPieceBetween(pos1, pos2, matrix)
    boolResult = false;
    x1 = pos1(1); y1 = pos1(2);
    x2 = pos2(1); y2 = pos2(2);
    if x1 ~= x2 && y1 ~= y2
        return
    end
    if x1 == x2
        step = sign(y2-y1);
        if abs(y2-y1) <= 1
            return;
        end
        for i = (y1+step) : step : (y2-step)
            if matrix(x1, i) ~= 0
                boolResult = true;
                return
            end
        end
    elseif pos1(2) == pos2(2)
        step = sign(x2-x1);
        if abs(x2-x1)<=1
            return
        end
        for i = (x1+step) : step : (x2-step)
            if matrix(i, y1) ~= 0
                boolResult = true;
                return
            end
        end
    end
end

function boolResult = hasPiece(pos, matrix)
    if matrix(pos(1), pos(2)) ~= 0
        boolResult = true;
    else
        boolResult = false;
    end
end

function boolResult = isSymmetric(matrix)
    [x,y] = size(matrix);
    for i = 1:y
        idxPool = ones(1,x);
        for j = 1:floor(x/2)
            if (matrix(j,i) ~= 0 || matrix(x+1-j,i) ~= 0) && ~isOfSameKind(matrix(j,i), matrix(x+1-j,i))
                boolResult = false;
                return;
            end
        end
    end
    boolResult = true;
end

function boolResult = isOfSameKind(v1, v2)
    if v1 == 0 || v2 == 0
        boolResult = false;
        return;
    end
    table = [1,2,2,4,4,6,6,8,8,10,10,12,12,12,12,12, 17,18,18,20,20,22,22,24,24,26,26,28,28,28,28,28];
    if table(v1) == table(v2)
        boolResult = true;
    else
        boolResult = false;
    end    
end