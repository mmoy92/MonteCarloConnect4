package {
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.StatusEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author Michael Moy (mmoy92)
	 */
	public class Main extends Sprite {
		static public var connectN:uint = 4;
		public var cols:uint = 7;
		public var rows:uint = 6;
		
		public var policy:Dictionary;
		public var returns:Vector.<ReturnEntry>;
		public var episode:Vector.<SApair>;
		public var curState:Board;
		
		public var phase:uint;
		public var evalStep:int;
		
		public var wins:uint;
		public var games:uint;
		public var numPolicies:uint;
		public var paused:Boolean;
		public var versusMode:Boolean;
		public var TD:Boolean;
		
		//Interface objects
		static public var txt:TextField;
		static public var txtb:TextField;
		static public var txtc:TextField;
		public var tutMC:MovieClip;
		private var format:TextFormat;
		public var fpsTxt:TextField;
		public var rowTxt:TextField;
		public var colTxt:TextField;
		public var goalTxt:TextField;
		public var tdTxt:TextField;
		public var fpsBtnLower:SimpleButton;
		public var fpsBtnGreater:SimpleButton;
		public var fpsBtnPause:SimpleButton;
		private var genBtn:SimpleButton;
		private var playBtn:SimpleButton;
		private var humanBtn:SimpleButton;
		private var tdBtn:SimpleButton;
		
		public function Main():void {
			if (stage) {
				initDisplay();
				init();
				addEventListener(Event.ENTER_FRAME, loop);
				stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			} else {
				addEventListener(Event.ADDED_TO_STAGE, init);
				
			}
		}
		
		/**
		 * Initializes the program's values.
		 * @param	e
		 */
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			returns = new Vector.<ReturnEntry>();
			policy = new Dictionary();
			wins = games = 0;
			numPolicies = 0;
			paused = true;
			versusMode = false;
			TD = false;
			
			print("", true);
			printb("", true);
			printc("", true);
			
			initRun();
		}
		
		/**
		 * Initializes values for a new episode.
		 */
		private function initRun():void {
			episode = new Vector.<SApair>();
			curState = new Board(rows, cols);
			
			phase = 0;
			evalStep = 0;
		}
		
		/**
		 * Main event loop. Progresses stages:
		 * 1. Episode generation stage
		 * 2. Episode evaluation stage
		 * 3. Policy evaluation stage
		 * Back to 1.
		 * @param	e
		 */
		private function loop(e:Event = null):void {
			if (!paused && !versusMode) {
				if (phase == 0) {
					genEpisode();
					if (stage.frameRate > 60) { //Turbo mode
						while (curState.status == Board.IN_PROGRESS) {
							genEpisode();
						}
					}
				} else if (phase == 1) {
					evalEpisode();
					if (stage.frameRate > 60) { //Turbo mode
						
						evalEpisode();
						evalEpisode();
						evalEpisode();
						
					}
				} else if (phase == 2) {
					evalPolicy();
					if (stage.frameRate > 60) { //Turbo mode
						
						evalPolicy();
						evalPolicy();
						evalPolicy();
						
					}
				}
				
				printPolicies();
			}
		}
		
		/**
		 * Updates the current policy based on an epsilon-soft policy.
		 * It uses 90% exploitation and 10% exploration to update a given
		 * policy in the episode.
		 */
		private function evalPolicy():void {
			if (phase == 2) {
				if (evalStep < episode.length) {
					var output:String = "Updating policy... \n";
					output += "Step: " + evalStep + "\n\n";
					output += ("Matching returns: \n");
					
					//Loop through each state in episode
					var move:SApair = episode[evalStep];
					var matchingReturns:Vector.<ReturnEntry> = new Vector.<ReturnEntry>();
					
					for each (var entry:ReturnEntry in returns) {
						//Get matching returns for this state
						if (move.state.equals(entry.move.state)) {
							matchingReturns.push(entry);
							
							output += (entry.toString());
							//Found all possible moves
							if (matchingReturns.length == cols) {
								break;
							}
						}
					}
					//90% vs 10% Exploit vs Explore
					var newPolicy:ReturnEntry;
					if (Math.random() < 0.90) {
						newPolicy = getMax(matchingReturns);
						printb("90% - Best Pick:\n\n" + newPolicy.toString() + "\n", true);
					} else {
						var possible:Vector.<uint> = move.state.possibleActions();
						newPolicy = lookupReturns(new SApair(move.state, possible[Math.floor(Math.random() * possible.length)]));
						printb("10% - Random Pick:\n\n" + newPolicy.toString() + "\n", true);
						
					}
					
					//Update corresponding policy
					if (policy[newPolicy.move.state.toString()] == null) {
						numPolicies++;
						
					}
					if (policy[newPolicy.move.state.toString()] == null || policy[newPolicy.move.state.toString()].x != newPolicy.move.action) {
						policy[newPolicy.move.state.toString()] = new Point(newPolicy.move.action, newPolicy.average);
						printb("\nPolicy updated!");
					}
					
					evalStep++;
					print(output, true);
				} else {
					initRun();
				}
			}
		}
		
		/**
		 * Evaluates the episode that just occured.
		 * Looks at each state-action pair in the episode and averages
		 * their calculated reward values into the returns list.
		 */
		private function evalEpisode():void {
			if (phase == 1) {
				if (evalStep < episode.length) {
					var output:String = "Evaluating (s,a) pairs...\n";
					
					output += "Step: " + evalStep + "\n";
					
					var move:SApair = episode[evalStep];
					
					var reward:Number = calculateReward(evalStep);
					
					output += move.state.toString() + "\n";
					output += "Action: " + move.action + "\n";
					output += "Value: " + reward;
					
					var r:ReturnEntry = lookupReturns(move);
					r.averageIn(reward);
					
					printb(r.toString());
					
					evalStep++;
					
					print(output, true);
				} else {
					phase = 2;
					evalStep = 0;
				}
			}
		}
		
		/**
		 * Calculates the relative reward of a move by discounting
		 * future rewards by a gamma of 0.5.
		 * @param	i The column to be chosen.
		 * @return Reward Q-value.
		 */
		private function calculateReward(i:int):Number {
			if (i < episode.length) {
				var move:SApair = episode[i];
				var immediateReward:Number = move.reward();
				return immediateReward + 0.5 * calculateReward(i + 1);
			}
			return 0;
		}
		
		/**
		 * Generates an episode (game) following the current policy.
		 * If no policy exists for a move, a random move is made if
		 * TD is disabled. If TD is enabled, a rewarding move is made.
		 */
		private function genEpisode():void {
			if (phase == 0) {
				if (curState.status != Board.IN_PROGRESS) {
					if (curState.status == Board.X_WINNER) {
						wins++;
						print(curState.toString(), true);
						print("X wins!\n");
					}
					games++;
					
				}
				//Generate a game using the policy
				if (curState.status == Board.IN_PROGRESS) {
					var output:String = "Generating new episode... \n";
					var pt:Point = Point(policy[curState.toString()]);
					if (pt) {
						//Found a policy for this state! Follow matching action.
						curState.place("x", pt.x);
						
						episode.push(new SApair(curState, pt.x));
						
						output += ("Found matching policy \n");
					} else {
						//This state has never been seen
						var newMove:SApair;
						
						if (TD) {
							//Temporal Difference
							newMove = placeBest("x");
						} else {
							//Random
							newMove = placeRandom("x");
						}
						episode.push(newMove);
						output += ("No policy, new move \n");
					}
					output += curState.toString();
					
					if (curState.status == Board.IN_PROGRESS && !versusMode) {
						//Do random turn for other player
						placeRandom("o");
					}
					
					print(output, true);
				} else {
					phase = 1;
					evalStep = 0;
					printb("", true);
				}
				
			}
		}
		
		/**
		 * Temporal difference decision. Applies a lookahead of one move and picks the move with the highest reward.
		 * @param	str Token string.
		 * @return The state-action pair representing the move.
		 */
		private function placeBest(str:String):SApair {
			//look ahead 1 and choose best reward.
			var possibleActions:Vector.<uint> = curState.possibleActions();
			var bestAction:uint = possibleActions[0];
			for each (var action:uint in possibleActions) {
				if (curState.reward(action) > curState.reward(bestAction)) {
					bestAction = action;
				}
			}
			curState.place("x", bestAction);
			
			return new SApair(curState, bestAction)
		}
		
		/**
		 * Places a given token on a random AVAILABLE column
		 * @param	str Token string.
		 * @return The state-action pair representing the move.
		 */
		private function placeRandom(str:String):SApair {
			var possibleActions:Vector.<uint> = curState.possibleActions();
			var randIndx:int = Math.floor(Math.random() * possibleActions.length);
			var randMove:SApair = new SApair(curState, possibleActions[randIndx]);
			curState.place(str, randMove.action);
			
			return randMove;
		}
		
		/**
		 * Searches returns list if the move already exists
		 * @param	move Move to be added to the returns list.
		 * @return The return entry matching this move.
		 */
		private function lookupReturns(move:SApair):ReturnEntry {
			for each (var r:ReturnEntry in returns) {
				if (r.move.equals(move)) {
					return r;
				}
			}
			var newEntry:ReturnEntry = new ReturnEntry(move);
			returns.push(newEntry);
			return newEntry;
		}
		
		/**
		 * Versus mode handler
		 * @param	e
		 */
		private function keyUpHandler(e:KeyboardEvent):void {
			if (versusMode) {
				if (e.keyCode - 48 < cols) {
					curState.place("o", e.keyCode - 48);
					
					if (curState.status == Board.IN_PROGRESS) {
						genEpisode();
					}
					
					print("Playing against the learner!\n\n" + curState.toString(), true);
					printb("Your turn!\n\n", true);
					
				} else {
					printb("Selected column " + int(e.keyCode - 48) + " is out of range.\n\n", true);
				}
				printb("Press a number key 0-9 to select a column.");
				
				if (curState.status == Board.X_WINNER) {
					printb("You have been defeated by the learner!\n\nClick 'play against' to try again.", true);
					versusMode = false;
				} else if (curState.status == Board.O_WINNER) {
					printb("Victory! You've bested the learner.\n\nImprove the AI by running the learning algorithm.\n\nClick 'play against' to play again.", true);
					versusMode = false;
				} else if (curState.status == Board.STALEMATE) {
					printb("Stalemate!\n\nImprove the AI by running the learning algorithm.\n\nClick 'play against' to play again.", true);
					versusMode = false;
				}
				
			}
		}
		
		// =======================================================================// 
		// USER INTERFACE INIT & METHODS
		// =======================================================================//
		private function initDisplay():void {
			format = new TextFormat("Arial", 20, 0x8EAD14, true);
			txt = new TextField();
			txt.defaultTextFormat = format;
			txt.width = 800 / 3;
			txt.height = 500;
			txt.wordWrap = true;
			addChild(txt);
			
			format.color = 0x1D9A9A;
			txtb = new TextField();
			txtb.defaultTextFormat = format;
			txtb.x = 800 / 3;
			txtb.width = 800 / 3;
			txtb.height = 500;
			txtb.wordWrap = true;
			addChild(txtb);
			
			format.color = 0xFFFFFF;
			
			txtc = new TextField();
			format.size = 15;
			format.bold = false;
			txtc.defaultTextFormat = format;
			txtc.selectable = true;
			txtc.x = 570;
			txtc.width = 800 / 3;
			txtc.height = 600;
			txtc.wordWrap = false;
			addChild(txtc);
			
			fpsTxt = TextField(getChildByName("fpsTxtDOC"));
			rowTxt = TextField(getChildByName("rowTxtDOC"));
			colTxt = TextField(getChildByName("colTxtDOC"));
			goalTxt = TextField(getChildByName("goalTxtDOC"));
			tdTxt = TextField(getChildByName("tdTxtDOC"));
			fpsBtnGreater = SimpleButton(getChildByName("fpsBtnGreaterDOC"));
			fpsBtnLower = SimpleButton(getChildByName("fpsBtnLowerDOC"));
			fpsBtnPause = SimpleButton(getChildByName("fpsBtnPauseDOC"));
			genBtn = SimpleButton(getChildByName("genBtnDOC"));
			playBtn = SimpleButton(getChildByName("playBtnDOC"));
			humanBtn = SimpleButton(getChildByName("humanBtnDOC"));
			tdBtn = SimpleButton(getChildByName("tdBtnDOC"));
			
			fpsBtnGreater.addEventListener(MouseEvent.CLICK, increaseFPS);
			fpsBtnLower.addEventListener(MouseEvent.CLICK, decreaseFPS);
			fpsBtnPause.addEventListener(MouseEvent.CLICK, pauseHandler);
			genBtn.addEventListener(MouseEvent.CLICK, genHandler);
			playBtn.addEventListener(MouseEvent.CLICK, playHandler);
			humanBtn.addEventListener(MouseEvent.CLICK, humanHandler);
			tdBtn.addEventListener(MouseEvent.CLICK, tdHandler);
			
			tutMC = MovieClip(getChildByName("tutDOC"));
		}
		
		private function tdHandler(e:MouseEvent):void {
			TD = !TD;
			tdTxt.text = TD ? "on" : "off";
		}
		
		private function humanHandler(e:MouseEvent):void {
			initRun();
			versusMode = true;
			paused = true;
			print("Playing against the learner!\n\n" + curState.toString(), true);
			printb("Your turn!\n\nPress a number key 0-9 to select a column.", true);
			printPolicies();
		}
		
		private function playHandler(e:MouseEvent):void {
			pauseHandler(null);
			paused = true;
			versusMode = false;
			var wins:int = 0;
			for (var i:uint = 0; i < 100; i++) {
				initRun();
				while (curState.status == Board.IN_PROGRESS) {
					genEpisode();
					if (curState.status == Board.X_WINNER) {
						wins++;
					}
				}
			}
			print("Won " + wins + " of 100 games.", true);
			printb("", true);
		}
		
		private function genHandler(e:MouseEvent):void {
			
			rows = uint(rowTxt.text);
			cols = uint(colTxt.text);
			Main.connectN = uint(goalTxt.text);
			
			init();
			versusMode = false;
			paused = false;
			updateFPS();
		
		}
		
		private function pauseHandler(e:MouseEvent):void {
			if (tutMC.visible) {
				tutMC.visible = false;
			}
			versusMode = false;
			paused = !paused;
			fpsTxt.text = paused ? "Paused" : (stage.frameRate) + " fps";
		}
		
		private function decreaseFPS(e:MouseEvent):void {
			if (stage.frameRate > 10) {
				stage.frameRate -= 10;
			} else {
				stage.frameRate--;
			}
			versusMode = false;
			paused = false;
			updateFPS();
		
		}
		
		private function increaseFPS(e:MouseEvent):void {
			if (stage.frameRate < 1) {
				stage.frameRate = 1;
			} else if (stage.frameRate < 10) {
				stage.frameRate++;
			} else {
				stage.frameRate += 10;
			}
			versusMode = false;
			paused = false;
			updateFPS();
		}
		
		private function updateFPS():void {
			fpsTxt.text = (stage.frameRate) + " fps";
			if (stage.frameRate > 60) {
				stage.frameRate = 70;
				fpsTxt.text = "TURBO";
			}
		}
		
		// =======================================================================// 
		// UTILITY FUNCTIONS
		// =======================================================================//
		private function getMax(matchingReturns:Vector.<ReturnEntry>):ReturnEntry {
			var maxEntry:ReturnEntry = matchingReturns[0]
			for each (var entry:ReturnEntry in matchingReturns) {
				if (entry.average > maxEntry.average) {
					maxEntry = entry;
				}
			}
			return maxEntry;
		}
		
		private function printPolicies():void {
			var output:String = "Policies: " + numPolicies + "\nWins: " + wins + "/" + games + "\n";
			for (var key:Object in policy) {
				output += "s" + SDBMHash(String(key)) + " \t> a" + policy[key].x + "\tQ: " + policy[key].y + "\n";
			}
			printc(output, true);
		}
		
		static public function print(str:String, clear:Boolean = false):void {
			if (clear) {
				txt.text = "";
			}
			txt.appendText(str);
		}
		
		static public function printb(str:String, clear:Boolean = false):void {
			if (clear) {
				txtb.text = "";
			}
			txtb.appendText(str);
		}
		
		static public function printc(str:String, clear:Boolean = false):void {
			if (clear) {
				txtc.text = "";
			}
			txtc.appendText(str);
		}
		
		static public function clone(source:Object):* {
			var myBA:ByteArray = new ByteArray();
			myBA.writeObject(source);
			myBA.position = 0;
			return (myBA.readObject());
		}
		
		static public function SDBMHash(str:String):uint {
			var hash:uint = 0;
			
			for (var i:int = 0; i < str.length; i++) {
				hash = uint(str.charCodeAt(i)) + (hash << 6) + (hash << 16) - hash;
			}
			
			return hash;
		}
	}

}