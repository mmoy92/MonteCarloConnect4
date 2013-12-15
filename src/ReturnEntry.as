package {
	
	/**
	 * Object that holds a state-action pairing and a running total of
	 * the SApair's performance over multiple episodes.
	 * @author Michael M
	 */
	public class ReturnEntry {
		public var move:SApair;
		public var average:Number;
		private var totalTrials:uint;
		
		public function ReturnEntry(move:SApair) {
			//May want to clone here
			this.move = move;
			average = 0;
			totalTrials = 0;
		}
		/**
		 * Integrates a new q-value into the average.
		 * @param	newQVal
		 */
		public function averageIn(newQVal:Number):void {
			average *= totalTrials;
			
			average += newQVal;
			
			totalTrials++;
			
			average /= totalTrials;
		}
		
		public function toString():String {
			
			return  "Q(s:"+ Main.SDBMHash(move.state.toString()) + ", a:" + move.action + ") = \n" + average + ", " + totalTrials + " trials\n";
		}
	}

}