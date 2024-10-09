classdef MonteCarloTreeSearch < handle
    %MCTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        node % struct: child, parent, score, status
             % score has the format: [numRedWin, numBlackWin, numDraw,
             %                        totalNum]
        numNodes % total nodes added so far
        c1 % wi/ni + c1*sqrt(ln(np)/ni)
        e % chineseChessEngine
        next % this tree search is for red or black
        iterates = 0; % total iterates of this search
        numFwdMoves = 100; % when applying random play, use this looking forward steps to avoid being checked.
        isExpandSucceeded = false;
    end
    
    methods
        function this = MonteCarloTreeSearch(s, N, c1, e)
            rootNode = struct('status', s, 'child', [], 'parent', 0, 'score', [0 0 0 0]);
            T(N) = rootNode;
            T(1) = T(N);
            T(end) = T(end-1);
            this.node = T;
%             this.node(N) = rootNode;
%             this.node(1) = this.node(end);
%             this.node(end) = this.node(end-1);
            this.numNodes = 1;
            this.c1 = c1;
            this.e = e;
            this.next = s.next;
        end
        
        function this = iterate(this)
            idx = selectNode(this, 1);
            this = expandNode(this, idx);
            if this.isExpandSucceeded
                result = simulate(this, idx);
                this = propagate(this, idx, result);
            else
                this = propagate(this, idx);
            end
            this.iterates = this.iterates+1;
                
        end
        
        function this = propagate(this, idx, result)
            if nargin == 2
            elseif nargin == 3
            end
        end
        
        function result = simulate(this, idx)
            childList = this.node(idx).child;
            result = [];
            parfor i = 1:length(childList)
                e = this.e;
                result(i) = playTillEnd(this.node(childList(i)).status, e, this.numFwdMoves);
            end
        end
        
        function this = expandNode(this, idx)
            this.isExpandSucceeded = false;
            if isLeaf(this, idx)
                this.e.setBoard(this.node(idx).status);
                moves = this.e.getAllValidMoves();
                if ~isempty(moves)
                    for i=1:size(moves,1)
                        newStatus = applyMove(this.node(idx).status, moves(i,:));
                        this.node(this.numNodes+1).status = newStatus;
                        this.node(this.numNodes+1).parent = idx;
                        this.node(this.numNodes+1).score = [0 0 0 0];
                        this.node(this.numNodes+1).child = [];
                        this.node(idx).child = [this.node(idx).child, this.numNodes+1];
                        this.numNodes = this.numNodes + 1;
                    end
                    this.isExpandSucceeded = true;
                end
            else
                error(['Node ', num2str(idx), ' is not a leaf node.']);
            end
        end
        
        function idx = selectNode(this, parentIdx)
            % search till the leaf
            idx = parentIdx;
            while ~isLeaf(this, idx)
                childList = this.node(idx).child;
                maxScore = 0;
                childIdx = 1;
                for i = 1:length(childList)
                    score = computeScore(childList(i));
                    if score > maxScore
                        maxScore = score;
                        childIdx = i;
                    end
                end
                idx = childIdx;
            end
        end
        
        function score = computeScore(this, idx)
            if this.node(idx).status.next == this.next
                wi = this.node(idx).score(this.next);
            else
                wi = this.node(idx).score(this.node(this.node(idx).parent).status.next);
            end
            ni = this.node(idx).score(4);
            if this.node(idx).parent ~= 0
                np = this.node(this.node(idx).parent).score(4);
            else
                error('No need to compute score for root.');
            end
            score = wi/ni + this.c1*sqrt(log(np)/ni);
        end
        
        function boolResult = isLeaf(this, idx)
            if isempty(this.node(idx).child)
                boolResult = true;
            else
                boolResult = false;
            end
        end
    end
    
end

