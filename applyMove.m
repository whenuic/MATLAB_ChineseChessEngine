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