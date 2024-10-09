function result = playTillEnd(s, e, numFwdMoves)
    for i = 1:numFwdMoves
        e.setBoard(s);
        moves = e.getAllValidMoves();
        if isempty(moves)
            if s.next == 1
                s.result = 2;
                result = 2;
                return;
            elseif s.next == 2
                s.result = 1;
                result = 1;
                return;
            end
            break;
        end
        noAttPiece = true;
        for j = 6:16
            if ~isequal(s.position(j, :), [0 0])
                noAttPiece = false;
                break;
            end
        end
        for j = 22:32
            if ~isequal(s.position(j, :), [0 0])
                noAttPiece = false;
                break;
            end
        end
        if noAttPiece
            result = 0;
            return;
        end
        
        % pick up a move from all valid moves
        randEvalPool = 1:size(moves,1);
        excludeEvalPool = [];
        winMoveIdx = [];
        e_tmp = e;
        for j = 1:size(moves,1)
            s_tmp = applyMove(s,moves(j,:));
            e_tmp.setBoard(s_tmp);
            moves_opp = e_tmp.getAllValidMoves();
            if isempty(moves_opp)
                winMoveIdx = j;
            end
            for k = 1:size(moves_opp,1)
                s_tmp2 = applyMove(s_tmp, moves_opp(k,:));
                e_tmp.setBoard(s_tmp2);
                if ~e_tmp.hasValidMove()
                    excludeEvalPool(end+1) = j;
                    break;
                end
            end
        end
        randEvalPool(excludeEvalPool) = [];
        if ~isempty(winMoveIdx)
            s = applyMove(s,moves(winMoveIdx,:));
            continue;
        end
        if isempty(randEvalPool)
            if s.next == 1
                result = 2;
            elseif s.next == 2
                result = 1;
            end
            return;
        else
            idx = randi([1 length(randEvalPool)]);
            s = applyMove(s,moves(idx,:));
        end        
    end
    result = 0;
end
