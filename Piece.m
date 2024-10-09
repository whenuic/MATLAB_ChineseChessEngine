classdef Piece < handle
    %CHINESECHESSPIECE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        color; % 1(red) or 2(black)
        pos; % [1 1] - BOARD POSITION!!! [1 1] starts bottom left
        isLive; % true or false
        possibleNextPos; % [1 1; 2 1; 3 1;] n-by-2
        displayName; % one of R(rook), N(knight), C(cannon), K(king), G(guard), B(bishop), P(pawn)
        enumValue; % Red    1-K, 2-GL, 3-GR, 4-BL, 5-BR, 6-NL, 7-NR, 8-RL
                   %        9-RR, 10-CL, 11-CR, 12-P1, 13-P3, 14-P5, 15-P7, 16-P9
                   % Black  17-K, 18-GL, 19-GR, 20-BL, 21-BR, 22-NL, 23-NR, 24-RL
                   %        25-RR, 26-CL, 27-CR, 28-P1, 29-P3, 30-P5, 31-P7, 32-P9
        circleHandle;
        textHandle;
        enumHandle;
    end
    
    methods
        function this = Piece(color, pos, enumValue, ax)
            this.color = color;
            this.pos = pos;
            this.enumValue = enumValue;
            this.isLive = true;
            this.possibleNextPos = [];
            this.displayName = getDispName(this.enumValue);
            [this.circleHandle, this.textHandle, this.enumHandle] = plotPiece(ax, this.pos, this.displayName, this.color, this.enumValue);
        end
        
        function possibleMoves = getPossibleMoves(this)
            switch this.displayName
                case 'K'
                    possibleMoves = this.pos + [1 0; 0 1; -1 0; 0 -1];
                case 'G'
                    possibleMoves = this.pos + [1 1; -1 1; -1 -1; 1 -1];
                case 'B'
                    possibleMoves = this.pos + [2 2; -2 2; -2 -2; 2 -2];
                case 'R'
                    x = this.pos(1); y = this.pos(2);
                    possibleMoves = [];
                    for i = 1:10
                        possibleMoves(end+1,:) = [x i];
                    end
                    possibleMoves(y,:) = [];
                    for i = 1:9
                        possibleMoves(end+1,:) = [i y];
                    end
                    possibleMoves(x+9,:) = [];
                case 'N'
                    possibleMoves = this.pos + [2 1;1 2;-1 2;-2 1;-2 -1;-1 -2;1 -2;2 -1];                    
                case 'C'
                    x = this.pos(1); y = this.pos(2);
                    possibleMoves = [];
                    for i = 1:10
                        possibleMoves(end+1,:) = [x i];
                    end
                    possibleMoves(y,:) = [];
                    for i = 1:9
                        possibleMoves(end+1,:) = [i y];
                    end
                    possibleMoves(x+9,:) = [];
                case 'P'
                    possibleMoves = this.pos + [1 0; -1 0; 0 1; 0 -1];
                otherwise
                    msgbox('Error piece type.', 'ErrorCanReach');
            end
        end
        
        function this = setDead(this)
            this.isLive = false;
            this.circleHandle.Visible = 'off';
            this.textHandle.Visible = 'off';
            this.enumHandle.Visible = 'off';
        end
        
        function this = setPos(this, newPos)
            deltaX = newPos(1) - this.pos(1);
            deltaY = newPos(2) - this.pos(2);
            this.pos = newPos;
            this.circleHandle.XData = this.circleHandle.XData + deltaX;
            this.circleHandle.YData = this.circleHandle.YData + deltaY;
            
            this.textHandle.Position(1) = this.textHandle.Position(1) + deltaX;
            this.textHandle.Position(2) = this.textHandle.Position(2) + deltaY;
            this.enumHandle.Position(1) = this.enumHandle.Position(1) + deltaX;
            this.enumHandle.Position(2) = this.enumHandle.Position(2) + deltaY;
        end
        
        function boolResult = canReach(this, newPos, boardMatrix)
            newX = newPos(1);
            newY = newPos(2);
            currX = this.pos(1);
            currY = this.pos(2);
            if newX == currX && newY == currY
                boolResult = false;
                msgbox('New pos is the same as currPos.', 'ErrorCanReach');
                return
            end
            % has own piece at new pos, return false
            if (this.color == 1 && hasRedPiece(newPos, boardMatrix)) ...
                    || (this.color == 2 && hasBlackPiece(newPos, boardMatrix))
                boolResult = false;
                return
            end
            switch this.displayName
                case 'K'
                    boolResult = canReachKing(this.color, newX, newY, currX, currY);
                case 'G'
                    boolResult = canReachGuard(this.color, newX, newY, currX, currY);
                case 'B'
                    boolResult = canReachBishop(this.color, newX, newY, currX, currY, boardMatrix);
                case 'R'
                    boolResult = canReachRook(newX, newY, currX, currY, boardMatrix);
                case 'N'
                    boolResult = canReachKnight(newX, newY, currX, currY, boardMatrix);
                case 'C'
                    boolResult = canReachCannon(newX, newY, currX, currY, boardMatrix);
                case 'P'
                    boolResult = canReachPawn(this.color, newX, newY, currX, currY);
                otherwise
                    msgbox('Error piece type.', 'ErrorCanReach');
            end
        end
    end
    
end

function boolResult = canReachPawn(color, newX, newY, currX, currY)
    boolResult = false;
    if norm([newX newY]-[currX currY]) ~= 1 || ~withinRange([newX newY], 1, 9, 1, 10)
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

function boolResult = canReachCannon(newX, newY, currX, currY, matrix)
    boolResult = false;
    if (newX ~= currX && newY ~= currY) || ~withinRange([newX newY], 1,9,1,10)
        return
    end
    if ~hasPiece([newX newY], matrix)
        boolResult = ~hasPieceBetween([currX currY], [newX newY], matrix);
    else
        diffVec = [newX newY]-[currX currY];
        stepVec = diffVec/norm(diffVec);
        if norm(diffVec) <= 1
            return
        end
        countInMiddle = 0;
        for i = 1:norm(diffVec)-1
            if hasPiece([currX currY]+stepVec*i, matrix)
                countInMiddle = countInMiddle + 1;
            end
        end
        if countInMiddle == 1
            boolResult = true;
        end
    end
end

function boolResult = canReachKnight(newX, newY, currX, currY, matrix)
    boolResult = false;
    if norm([newX newY]-[currX currY])~= sqrt(5) || ~withinRange([newX newY], 1, 9, 1, 10)
        return
    end
    stepX = newX-currX;
    stepY = newY-currY;
    if norm(stepX) == 2
        if ~hasPiece([currX+stepX/2 currY], matrix)
            boolResult = true;
        end
    end
    if norm(stepY) == 2
        if ~hasPiece([currX currY+stepY/2], matrix)
            boolResult = true;
        end
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

function boolResult = canReachBishop(color, newX, newY, currX, currY, matrix)
    boolResult = false;
    if norm([newX newY]-[currX currY]) ~= 2 * sqrt(2) ...
            || hasPiece([(newX+currX)/2, (newY+currY)/2], matrix)
        return
    end
    if (color == 1 && withinRange([newX newY], 1, 9, 1, 5)) ...
            || (color == 2 && withinRange([newX newY], 1, 9, 6, 10))
            boolResult = true;
    end
end

function boolResult = canReachGuard(color, newX, newY, currX, currY)
    boolResult = false;
    if norm([newX newY]-[currX currY]) ~= sqrt(2)
        return
    end
    if (color == 1 && withinRange([newX newY], 4,6,1,3)) ...
            || (color == 2 && withinRange([newX newY], 4,6,8,10))
        boolResult = true;
    end
end

function boolResult = canReachKing(color, newX, newY, currX, currY)
    boolResult = false;
    if norm([newX newY]-[currX currY]) ~= 1
        return
    end
    if (color == 1 && withinRange([newX newY], 4,6,1,3)) ...
            || (color == 2 && withinRange([newX newY], 4,6,8,10))
            boolResult = true;
    end
end


function [circleH, textH, enumH] = plotPiece(ax, pos, dispName, color, enumValue)
    if color == 1
        colorStr = 'red';
    elseif color == 2
        colorStr = 'black';
    end
    circleH = plotCircle(ax, pos, colorStr);
    textH = printText(ax, pos, dispName, colorStr);
    enumH = printText(ax, pos-[0 0.35], num2str(enumValue), colorStr);
end

function h = printText(ax, pos, textStr, colorStr)
    x = pos(1); y = pos(2);
    xOffset = -0.15;
    h = text(ax, x+xOffset, y, textStr);
    set(h, 'fontsize', 15);
    set(h, 'fontweight', 'bold');
    set(h, 'color', colorStr);
end

function h = plotCircle(ax, pos, colorStr)
    x = pos(1); y = pos(2);
    r = 0.46;
    ang=0:0.02:2*pi;
    xp=r*cos(ang);
    yp=r*sin(ang);
    h = plot(ax, x+xp, y+yp);
    set(h, 'linewidth', 1);
    set(h, 'color', colorStr);
end

function dispName = getDispName(enumValue)
    if enumValue == 1 || enumValue == 17
        dispName = 'K';
    elseif enumValue == 2 || enumValue == 3 || enumValue == 18 || enumValue == 19
        dispName = 'G';
    elseif enumValue == 4 || enumValue == 5 || enumValue == 20 || enumValue == 21
        dispName = 'B';
    elseif enumValue == 6 || enumValue == 7 || enumValue == 22 || enumValue == 23
        dispName = 'N';
    elseif enumValue == 8 || enumValue == 9 || enumValue == 24 || enumValue == 25
        dispName = 'R';
    elseif enumValue == 10 || enumValue == 11 || enumValue == 26 || enumValue == 27
        dispName = 'C';
    else
        dispName = 'P';
    end
end

function boolResult = hasRedPiece(pos, matrix)
    val = matrix(pos(1), pos(2));
    if val <= 16 && val >= 1
        boolResult = true;
    else
        boolResult = false;
    end
end

function boolResult = hasBlackPiece(pos, matrix)
    val = matrix(pos(1), pos(2));
    if val <= 32 && val >= 17
        boolResult = true;
    else
        boolResult = false;
    end
end

function boolResult = hasPiece(pos, matrix)
    if matrix(pos(1), pos(2)) ~= 0
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
        step = (y2-y1)/norm(y2-y1);
        if norm(y2-y1) <= 1
            return;
        end
        for i = (y1+step) : step : (y2-step)
            if hasPiece([x1, i], matrix)
                boolResult = true;
                return
            end
        end
    elseif pos1(2) == pos2(2)
        step = (x2-x1)/norm(x2-x1);
        if norm(x2-x1)<=1
            return
        end
        for i = (x1+step) : step : (x2-step)
            if hasPiece([i y1], matrix)
                boolResult = true;
                return
            end
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