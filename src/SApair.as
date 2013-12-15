package {
	import flash.geom.Point;
	
	/**
	 * Object for a state-action pairing.
	 * @author Michael Moy
	 */
	public class SApair {
		public var state:Board;
		public var action:uint;
		
		public function SApair(state:Board, action:uint) {
			this.state = state.clone();
			this.action = action;
		}
		public function reward():Number {
			return state.reward(action);
		}
		public function equals(other:SApair):Boolean {
			return (state.toString() == other.state.toString() && action == other.action);
		}
	}

}