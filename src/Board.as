package {
	import flash.geom.Point;
	
	/**
	 * Board class represents a game state at any point in time.
	 * 
	 * @author Michael M
	 */
	public class Board {
		public static const IN_PROGRESS:uint = 0;
		public static const X_WINNER:uint = 1;
		public static const O_WINNER:uint = 2;
		public static const STALEMATE:uint = 3;
		
		public var rows:uint;
		public var cols:uint;
		public var grid:Array;
		public var status:uint;
		/**
		 * Initialize a new state with rows x cols.
		 * @param	rows
		 * @param	cols
		 */
		public function Board(rows:uint = 4, cols:uint = 5) {
			status = IN_PROGRESS;
			this.rows = rows;
			this.cols = cols;
			
			grid = new Array(rows);
			
			for (var i:uint = 0; i < rows; i++) {
				grid[i] = new Array(cols);
				for (var j:uint = 0; j < cols; j++) {
					grid[i][j] = "_";
				}
			}
		}
		/**
		 * Returns a vector containing all possible actions for this state.
		 * @return
		 */
		public function possibleActions():Vector.<uint> {
			var ret:Vector.<uint> = new Vector.<uint>();
			
			for (var j:uint = 0; j < cols; j++) {
				
				if (grid[0][j] == "_") {
					ret.push(j);
				}
				
			}
			return ret;
		}
		private function checkStalemate():uint {
			for (var i:uint = 0; i < rows; i++) {
				for (var j:uint = 0; j < cols; j++) {
					if (grid[i][j] == "_") {
						return IN_PROGRESS;
					}
				}
			}
			return STALEMATE;
		}
		/**
		 * Returns a reward based on the given action.
		 * Assumes that it is currently the learner's turn.
		 * 
		 * Gives more reward for winning moves than blocking moves.
		 * @param	col
		 * @return
		 */
		public function reward(col:uint):Number {
			var loc:Point = placementLoc(col);
			
			//+200 for winning move
			place("x", col);
			if (loc != null) {//Undo move
				grid[loc.x][loc.y] = "_";
			}
			if (status == X_WINNER) {
				return 200;
			} 
			
			//+100 for blocking a win
			place("o", col);
			if (loc != null) {//Undo move
				grid[loc.x][loc.y] = "_";
			}
			if (status == O_WINNER) {
				return 100;
			} 
			
			//+0 else
			return 0;
		}
		/**
		 * Places a token in the given column and updates the state victory progress.
		 * @param	sym
		 * @param	col
		 */
		public function place(sym:String, col:uint):void {
			var loc:Point = placementLoc(col);
			if (loc != null) {
				grid[loc.x][loc.y] = sym;
				if (winHorizontal(loc) || winVertical(loc) || winDiagonal(loc)) {
					status = (sym == "x" ? X_WINNER : O_WINNER);
				} else {
					status = checkStalemate();
				}
			} else {
				//Shouldn't ever happen
				status = STALEMATE;
			}
		}
		
		// =======================================================================// 
		// Win condition methods.
		// =======================================================================//
		public function winDiagonal(loc:Point):Boolean {
			return winDiagDir(loc, true) || winDiagDir(loc, false);
		}
		
		public function winDiagDir(loc:Point, leftward:Boolean):Boolean {
			var connect:uint = 1;
			var hs:int = leftward ? -1 : 1;
			//var vs:int = upward ? -1 : 1;
			var i:uint = loc.x;
			var j:uint = loc.y;
			//Set ij to upperleft/upperright depending on dir
			while (inBounds(i - 1, j - hs)) {
				i--;
				j -= hs;
			}
			while (inBounds(i, j) && inBounds(i + 1, j + hs)) {
				if (grid[i][j] == grid[i + 1][j + hs] && grid[i][j] != "_") {
					connect++;
				} else {
					connect = 1;
				}
				if (connect == Main.connectN) {
					return true;
				}
				i++;
				j += hs;
			}
			return false;
		}
		
		public function winVertical(loc:Point):Boolean {
			var connect:uint = 1;
			for (var i:uint = rows; i > 0; i--) {
				
				if (inBounds(i, loc.y) && inBounds(i - 1, loc.y)) {
					if (grid[i][loc.y] == grid[i - 1][loc.y] && grid[i][loc.y] != "_") {
						connect++;
					} else {
						connect = 1;
					}
					
					if (connect == Main.connectN) {
						return true;
					}
				}
			}
			return false;
		}
		
		public function winHorizontal(loc:Point):Boolean {
			var connect:uint = 1;
			for (var j:uint = 0; j < cols; j++) {
				if (inBounds(loc.x, j) && inBounds(loc.x, j + 1)) {
					
					if (grid[loc.x][j] == grid[loc.x][j + 1] && grid[loc.x][j] != "_") {
						connect++;
					} else {
						connect = 1;
					}
					
					if (connect == Main.connectN) {
						return true;
					}
				}
			}
			return false;
		}
		
		// =======================================================================// 
		// Utility Methods
		// =======================================================================//
		public function placementLoc(c:uint):Point {
			for (var i:int = rows - 1; i >= 0; i--) {
				if (grid[i][c] == "_") {
					return new Point(i, c);
				}
			}
			return null;
		}
		
		private function inBounds(x:int, y:int):Boolean {
			return (x >= 0 && x < rows && y >= 0 && y < cols);
		}
		
		public function equals(other:Board):Boolean {
			return toString() == other.toString();
		}
		
		public function toString():String {
			var topStr:String = "_ ";
			var gridStr:String = "";
			for (var i:uint = 0; i < rows; i++) {
				
				var line:String = i + " ";
				for (var j:uint = 0; j < cols; j++) {
					line += grid[i][j] + " ";
					if (i == 0) {
						topStr += j + " ";
					}
				}
				gridStr += line + "\n";
			}
			return (topStr + "\n" + gridStr);
		}
		
		public function clone():Board {
			var newBoard:Board = new Board(rows, cols);
			newBoard.grid = Main.clone(grid);
			return newBoard;
		}
	}

}