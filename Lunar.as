/**
* Lunar.as
* 
* Purpose: Main entry point for Lunar game.
* 
* Created: 2007.08.04
* 
* @author abraginsky@gmail.com
* 
* Credits:
*   . Earthrise background image courtesy of http://www.astronomy.com/asy/objects/images/earthrise_500.jpg
*   . Sound samples from the film "2001" courtsey of MGM
*/

class Lunar
{
	var mc:MovieClip;
	var ship:Ship;
	var intervalID:Number;
	
	var width:Number;
	var height:Number;
	
	var starCount:Number = 200;
	var starScaleMin:Number = 100;
	var starScaleMax:Number = 100;
	var starAlphaMin:Number = 25;
	var starAlphaMax:Number = 100;
	var starTwinkleRate:Number = 5;//50;
	var starTwinkleTime:Number = 1;
	
	var gravity:Number = .3;//5;
	var maxLandingV:Number = 3.50; // If ship lands on platform with vy or vx greater than this, count as a crash
	
	var heartBeat:Number = 80; // game loop interval timeout
	var initTime:Number;
	var pauseTime:Number;
	
	var maxLives:Number = 3;
	var lives:Number = maxLives;
	
	var gameOver:Boolean = false;
	var gameStarted:Boolean = false;
	var paused:Boolean = false;

	var platforms:Array;
	var platformDirection:Number = 1;
	var totalPlatforms:Number = 3;
	
	var maxLevels:Number = 4;
	var gameLevel:Number = 1; // Each time a game is won, increment gameLevel and update platforms
	var levels:Array = [["platform1","platform2","platform3"],["platform1","platform2"],["platform1","platform2"],["platform3"]];

	// Scoring
	var scoreLevelBonusPt:Number = 100;
	var scoreFuelBonusPt:Number = 50;
	var scoreFuelBonusPct:Number = 0.5; // if level cleared with fuel %age greater than this amount, award fuel bonus
	var scoreTimeBonusPt:Number = 25; // if total time to land < 10s, award time bonus
	var timeBonusTime:Number = 10000;//5000; // ms
	var levelTime:Number = 0;
	var bestTime:Number = 0;
	var newBestTime:Boolean = false;
	var totalScore:Number = 0;
	var levelBonus:Boolean = false;
	var fuelBonus:Boolean = false;
	var timeBonus:Boolean = false;
	
	var interstitialTime:Number = 3000;
	var interstitialShown:Boolean = false; // don't allow pause during interstitials
	
	var debugMode:Boolean = true; // if false, level skip keys disabled
	
	// Default constructor
	function Lunar(mc:MovieClip)
	{		
		this.mc = mc;		
		
		this.width = Stage.width;
		this.height = Stage.height;
		
		initShip();		
		initStars();
		initKeyListener();
		
		_root.interstitialTimerDuration = this.interstitialTime;
		
		// Hide instruments
		this.mc.instruments_mc._visible = false;

		// Show preload
		this.mc.bg_mc.interstitial_mc.gotoAndStop("_preLoad");
		
		// Load external sounds
		this.mc.external_sounds_mc.loadMovie("sounds.swf");
				
		// Start intro animation
		//this.mc.bg_mc.interstitial_mc.gotoAndStop("_intro");				
	}	
	
	// Create ship
	private function initShip()
	{
		this.ship = new Ship(this.mc);
	}
	
	// Generate random star background
	private function initStars()
	{
		for(var i:Number = 0; i < this.starCount; i++)
		{
			var x:Number;
			var y:Number;
			var starScale:Number;
			var starAlpha:Number;
			
			x = randRangeFloor(0, this.width);
			y = randRangeFloor(0, this.mc.bg_mc.ground_mc._y);
			starScale = randRangeFloor(this.starScaleMin, this.starScaleMax);
			starAlpha = randRangeFloor(this.starAlphaMin, this.starAlphaMax);
			
			var curStar:MovieClip;
			curStar = this.mc.bg_mc.stars_mc.attachMovie("star_mc", "star_"+i, this.mc.bg_mc.stars_mc.getNextHighestDepth(), {_x:x,_y:y,_xscale:starScale,_yscale:starScale,_alpha:starAlpha});
		}
	}
	
	// Restart game
	private function restart()
	{
		trace("## restart()");		
			
		// Stop intro hiss  if it's still playing
		if(!this.gameStarted)
			this.stopSnd("hiss");
			
		this.gameStarted = true;		
		
		this.mc.bg_mc.interstitial_mc.gotoAndStop("_off");
		this.interstitialShown = false;
		
		this.playSnd("background");
		
		this.initPlatforms();
		
		if(this.gameOver)
		{		
			// Reset for a new game
			this.totalScore = 0;
			this.ship.fuel = 100;
			this.lives = this.maxLives;			
			this.gameOver = false;
			this.mc.platforms_mc._visible = true;
		}

		// Re-init ship
		this.ship.setVisibility(true);
		this.ship.resetShip();
		
		this.levelBonus = false;
		this.fuelBonus = false;
		this.timeBonus = false;
		
		// Kill previous game loop interval
		clearInterval(this.intervalID);
		this.intervalID = undefined;
		
		// Start game loop interval
		this.intervalID = setInterval(this, "manage", this.heartBeat);
		
		// Set initial time
		this.initTime = getTimer();
	}
	
	private function initPlatforms()
	{
		// Clear platforms
		for(var i:Number = 0; i < this.totalPlatforms; i++)
		{
			var cur:Number = i+1;
			removeMovieClip(eval("this.mc.platforms_mc.platform"+cur));
		}
		
		// Set platforms for current level
		this.platforms = this.levels[this.gameLevel-1];
		
		// platform y = 331.3
		var platCount:Number = 1;
		for(var curPlat:String in this.platforms)
		{
			var platStr:String = this.platforms[curPlat];
			var x:Number;
			
			switch(platStr)
			{
				case "platform1":
					x = 83.1;
					break;
				case "platform2":
					x = 399.0;
					break;
				case "platform3":
					x = 245;
					break;				
			}
			
			var curPlatform:MovieClip;
			curPlatform = this.mc.platforms_mc.attachMovie("platform_mc", platStr, this.mc.platforms_mc.getNextHighestDepth(), {_x:x, _y:331.1});
						
			platCount++;
		}
		
		this.mc.platforms_mc._visible = true;		
	}
	
	private function stop()
	{
		// Kill previous enterframe manager
		clearInterval(this.intervalID);
		this.intervalID = undefined;
		
		// Stop any looping sounds
		this.stopSnd();
	}
	
	// Manage simulation
	private function manage()
	{
		if(!this.paused)
		{
			// Restore initTime to point after pause time
			if(this.pauseTime != undefined)
			{				
				this.initTime += getTimer() - this.pauseTime;
				this.pauseTime = undefined;
			}
			
			// Update ship position based on current velocity
			this.ship.move();
									
			// Apply gravity
			this.ship.vy += this.gravity;
						
			// At higher levels, move platforms
			this.movePlatforms(this.gameLevel);		
			
			// Update instrument displays
			this.updateDisplays();
			
			// Flash vy and/or vx if they're > maxLandingV and flash fuel if < 50% left
			this.checkForWarnings();

			// Ship has hit bottom without hitting a platform or left the top of the screen? (lose)
			this.checkWinLose();	
		}
		else
		{
			// Save time so time bonus is accurate
			if(this.pauseTime == undefined)
				this.pauseTime = getTimer();		
		}
		
		// Twinkle star field on a periodic basis
		// (Yes I know the atmosphere on the Moon is non-existant, but this is a game remember :p)
		if(this.starTwinkleTime % this.starTwinkleRate == 0)
			this.twinkleStars();
		
		if(this.starTwinkleTime > 1000)
			this.starTwinkleTime = 1;
			
		this.starTwinkleTime += 1;		
	}
	
	// Check for win/lose state
	private function checkWinLose()
	{
		if(this.ship.y > this.ship.yMax || this.ship.y <= 0)
			this.lose();
		else
		{
			// Ship landed on a platform with correct velocities? (win)
			for(var i:Number = 0; i < this.platforms.length; i++)
			{
				var curPlatform:MovieClip = eval("this.mc.platforms_mc."+platforms[i]);
				
				if(curPlatform.hitTest(this.ship.body_mc))
				{
					if(this.ship.vy <= this.maxLandingV && Math.abs(this.ship.vx) <= this.maxLandingV && this.ship.mc._x >= curPlatform._x && this.ship.mc._x + this.ship.mc._width <= curPlatform._x + curPlatform._width)
						this.win();
					else
						this.lose();
						
					break;
				}
			}
		}		
	}
	
	// Based on current level, move platforms
	private function movePlatforms(curLevel:Number)
	{
		switch(curLevel)
		{
			case 3:
			{
				var curPlatform1:MovieClip = eval("this.mc.platforms_mc."+platforms[0]);

				if(curPlatform1._x + curPlatform1._width > Stage.width || curPlatform1._x < 0)
				{
					this.platformDirection *= -1;
				}

				curPlatform1._x += this.platformDirection;				

				var curPlatform2:MovieClip = eval("this.mc.platforms_mc."+platforms[1]);	

				this.platformDirection *= -1;

				if(curPlatform2._x + curPlatform2._width > Stage.width || curPlatform2._x < 0)
				{
					this.platformDirection *= -1;
				}
					
				curPlatform2._x += this.platformDirection;		

				this.platformDirection *= -1;			
				
				break;
			}			
			case 4:
			{
				var curPlatform:MovieClip = eval("this.mc.platforms_mc."+platforms[0]);

				if(curPlatform._x + curPlatform._width > Stage.width || curPlatform._x < 0)
				{
					this.platformDirection *= -1;
				}
					
				curPlatform._x += this.platformDirection;				
				
				break;
			}
		}		
	}
	
	private function playSnd(which:String)
	{
		switch(which)
		{
			case "background":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_background_mc.gotoAndPlay("_on");
				break;
			case "lowFuel":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_lowFuel_mc.gotoAndPlay("_on");
				break;
			case "lowAltitude":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_lowAltitude_mc.gotoAndPlay("_on");
				break;
			case "win":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_win_mc.gotoAndPlay("_on");
				break;
			case "lose":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_lose_mc.gotoAndPlay("_on");
				break;		
			case "hiss":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_hiss_mc.gotoAndPlay("_on");
				break;		
		}
	}
	
	private function stopSnd(which:String)
	{
		switch(which)
		{
			case "background":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_background_mc.gotoAndStop("_off");
				break;
			case "lowFuel":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_lowFuel_mc.gotoAndStop("_off");
				break;
			case "lowAltitude":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_lowAltitude_mc.gotoAndStop("_off");
				break;
			case "win":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_win_mc.gotoAndStop("_off");
				break;
			case "lose":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_lose_mc.gotoAndStop("_off");
				break;	
			case "hiss":
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_hiss_mc.gotoAndStop("_off");
				break;		
			default:
			{
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_background_mc.gotoAndStop("_off");
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_lowFuel_mc.gotoAndStop("_off");
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_lowAltitude_mc.gotoAndStop("_off");
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_win_mc.gotoAndStop("_off");
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_lose_mc.gotoAndStop("_off");
				this.mc.external_sounds_mc.mc.snd_container_mc.snd_hiss_mc.gotoAndStop("_off");
			}
		}
	}
	
	// Flash vy and/or vx if they're > maxLandingV and flash fuel if < 50% left	
	private function checkForWarnings(reset:Boolean)
	{
		if(reset)
		{
			this.mc.instruments_mc.ship_vx_txt.textColor = 0xFFFFFF;	
			this.mc.instruments_mc.ship_vy_txt.textColor = 0xFFFFFF;		
			this.mc.instruments_mc.ship_fuel_label.textColor = 0xFFFFFF;			
		}
		else
		{
			var lowFuel:Boolean = false;
			
			if(this.ship.fuel/this.ship.fuelMax < 0.5)
			{
				lowFuel = true;
				
				this.playSnd("lowFuel");
				//this.stopSnd("background");
				
				if(_root.fuelFlashStart == undefined)
					_root.fuelFlashStart = 1;
									
				if(_root.fuelFlashStart % 2 == 0)
				{
					this.mc.instruments_mc.ship_fuel_label.textColor = 0xFF0000;
				}
				else
				{
					this.mc.instruments_mc.ship_fuel_label.textColor = 0xFFFFFF;				
				}
				
				_root.fuelFlashStart += 1;
			}
			else
			{
				this.stopSnd("lowFuel");
				//this.playSnd("background");
				
				_root.fuelFlashStart = 1;
				this.mc.instruments_mc.ship_fuel_label.textColor = 0xFFFFFF;	
			}
			
			if(this.ship.vx > this.maxLandingV)
			{
				if(!lowFuel)
				{
					this.playSnd("lowAltitude");
					//this.stopSnd("background");
				}
				
				if(_root.vxFlashStart == undefined)
					_root.vxFlashStart = 1;
									
				if(_root.vxFlashStart % 2 == 0)
				{
					this.mc.instruments_mc.ship_vx_txt.textColor = 0xFF0000;
				}
				else
				{
					this.mc.instruments_mc.ship_vx_txt.textColor = 0xFFFFFF;				
				}
				
				_root.vxFlashStart += 1;
			}
			else
			{
				this.stopSnd("lowAltitude");
				//this.playSnd("background");
				
				_root.vxFlashStart = 1;
				this.mc.instruments_mc.ship_vx_txt.textColor = 0xFFFFFF;	
			}
			
			if(this.ship.vy > this.maxLandingV)
			{
				if(!lowFuel)
				{
					this.playSnd("lowAltitude");
					//this.stopSnd("background");					
				}
				
				if(_root.vyFlashStart == undefined)
					_root.vyFlashStart = 1;
									
				if(_root.vyFlashStart % 2 == 0)
				{
					this.mc.instruments_mc.ship_vy_txt.textColor = 0xFF0000;
				}
				else
				{
					this.mc.instruments_mc.ship_vy_txt.textColor = 0xFFFFFF;				
				}
				
				_root.vyFlashStart += 1;
			}
			else
			{
				this.stopSnd("lowAltitude");
				//this.playSnd("background");
				
				_root.vyFlashStart = 1;
				this.mc.instruments_mc.ship_vy_txt.textColor = 0xFFFFFF;	
			}				
		}	
	}
	
	// Update instrument displays
	private function updateDisplays()
	{
		// Update text
		this.mc.instruments_mc.ship_ax_txt.text = formatDecimals(this.ship.ax, 2);
		this.mc.instruments_mc.ship_ay_txt.text = formatDecimals(this.ship.ay, 2);
		this.mc.instruments_mc.ship_vx_txt.text = formatDecimals(this.ship.vx, 2);
		this.mc.instruments_mc.ship_vy_txt.text = formatDecimals(this.ship.vy, 2);
		this.mc.instruments_mc.ship_x_txt.text = formatDecimals(this.ship.x - this.ship.startX, 2);
		this.mc.instruments_mc.ship_y_txt.text = formatDecimals(this.ship.startY - this.ship.y, 2);
		this.mc.instruments_mc.ship_fuel_txt.text = formatDecimals(this.ship.fuel, 2);

		// Update meters
		this.mc.instruments_mc.fuel_meter_mc.bar_mc._width = this.ship.fuel/100 * this.mc.instruments_mc.fuel_meter_mc.bg_mc._width;

		if(_root.center_bar_x_pos == undefined)
			_root.center_bar_x_pos = this.mc.instruments_mc.ax_meter_mc.bar_mc._x;

		if(this.ship.ax/this.ship.axMax < 0)
		{
			this.mc.instruments_mc.ax_meter_mc.bar_mc._x = this.mc.instruments_mc.ax_meter_mc.bg_mc._width/2 - Math.abs((this.ship.ax/this.ship.axMax) * (this.mc.instruments_mc.ax_meter_mc.bg_mc._width/2));
			this.mc.instruments_mc.ax_meter_mc.bar_mc._width = Math.abs((this.ship.ax/this.ship.axMax) * (this.mc.instruments_mc.ax_meter_mc.bg_mc._width/2));
		}
		else
		{
			this.mc.instruments_mc.ax_meter_mc.bar_mc._x = _root.center_bar_x_pos;
			this.mc.instruments_mc.ax_meter_mc.bar_mc._width = Math.abs((this.ship.ax/this.ship.axMax) * (this.mc.instruments_mc.ax_meter_mc.bg_mc._width/2));				
		}

		this.mc.instruments_mc.ay_meter_mc.bar_mc._width = (this.ship.ay/this.ship.ayMax) * (this.mc.instruments_mc.ay_meter_mc.bg_mc._width);			
		
		// Update number of lives left indicator
		this.mc.lives_mc.gotoAndStop("_"+this.lives);		
	}
	
	// Show win interstitial
	private function win()
	{
		// Shutdown ship
		this.ship.shutDown(false);
		this.stop();		
		
		// Level win bonus
		this.totalScore += this.scoreLevelBonusPt;
		this.levelBonus = true;
		
		// Check for fuel bonus
		if(this.ship.fuel/this.ship.fuelMax > this.scoreFuelBonusPct)
		{
			this.totalScore += this.scoreFuelBonusPt;
			this.fuelBonus = true;
		}
			
		// Check for time bonus
		this.levelTime = getTimer() - this.initTime;
		
		if(this.levelTime < this.timeBonusTime)
		{
			this.totalScore += this.scoreTimeBonusPt;
			this.timeBonus = true;
		}
		
		// Update best time
		if(this.bestTime == 0)
		{
			this.bestTime = this.levelTime;
		}
		else if(this.levelTime < this.bestTime)
		{
			trace("## New best time! "+levelTime);
			this.bestTime = this.levelTime;
			this.newBestTime = true;
		}
		else
			this.newBestTime = false;
		
		// Increment level
		if(this.gameLevel + 1 <= this.maxLevels)
			this.gameLevel += 1;
			
		this.mc.bg_mc.interstitial_mc.gotoAndStop("_win");		
		this.stopSnd("background");
		this.playSnd("win");		
	}
	
	// Show lose interstitial
	private function lose()
	{
		// Shutdown ship
		this.ship.shutDown(true);
		this.stop();		
		
		this.lives -= 1;

		// Update number of lives left indicator
		this.mc.lives_mc.gotoAndStop("_"+this.lives);		
		
		if(this.lives > 0)
        {
            if(this.ship.y <= 0)
			{
                this.mc.bg_mc.interstitial_mc.gotoAndStop("_signalLost");
				this.stopSnd("background");
			}
            else
			{
                this.mc.bg_mc.interstitial_mc.gotoAndStop("_lose");
				
				this.stopSnd("background");
				this.playSnd("lose");
			}
        }
		else
		{
			this.gameOver = true;
			
			// Hide platforms
			this.mc.platforms_mc._visible = false;

			this.mc.bg_mc.interstitial_mc.gotoAndStop("_gameOver");	
			
			this.stopSnd("background");
			this.playSnd("lose");
			
			// Reset level
			this.gameLevel = 1;
		}			
	}
	
	// Called by level interstitial
	private function clearLevel()
	{	
		// Reset ship and clear instruments
		this.ship.resetShip();		
		this.ship.setVisibility(false);
		this.ship.fuel = 0;
		this.checkForWarnings(true);
		this.updateDisplays();		
	}
	
	// Show level interstitial
	private function level()
	{		
		this.mc.bg_mc.interstitial_mc.gotoAndStop("_level");	
		this.mc.platforms_mc._visible = false;
		this.ship.setVisibility(false);
	}
	
	// Show current score after winning a level
	private function showScore()
	{
		this.mc.bg_mc.interstitial_mc.gotoAndStop("_score");	
	}
	
	// Randomly sets star alpha
	private function twinkleStars()
	{
		for(var i:Number = 0; i < this.starCount; i++)
		{
			if(i % 2 == 0)
			{
				var starAlpha:Number;
				
				starAlpha = randRangeFloor(this.starAlphaMin, this.starAlphaMax);
				
				var curStar:MovieClip;
				curStar = eval("this.mc.bg_mc.stars_mc.star_"+i);
				curStar._alpha = starAlpha;
			}
		}		
	}
	
	// Initializes keyboard events
	private function initKeyListener()
	{
		var keyListener:Object = {};
		var k_cb:Object = {scope:this, func:this.keyAction};
		keyListener.cb = k_cb;
		
		keyListener.onKeyUp = function() 
		{
			var keyCode:Number = Key.getCode();
			this.cb.func.apply(this.cb.scope, ["up", keyCode, Key.isDown(Key.SHIFT)]);
		};
		
		keyListener.onKeyDown = function() 
		{
			var keyCode:Number = Key.getCode();
			this.cb.func.apply(this.cb.scope, ["down", keyCode, Key.isDown(Key.SHIFT)]);
		};
		
		Key.removeListener(keyListener);
		Key.addListener(keyListener);
	}
	
	// Handles keyboard events
	private function keyAction(state:String, keyCode:Number, shiftKey:Boolean):Void 
	{
		if(!this.paused || keyCode == 80)
		{
			//trace("## keyAction(state, keyCode, shiftKey) = ("+state+", "+keyCode+", "+shiftKey+")");
			
			if(state == "down")
			{
				switch (keyCode)
				{
					// up
					case 38:
						if(!this.ship.isRunning)
							this.ship.thrustUp();
						break;
					// down
					case 40:
						if(!this.ship.isRunning)
							this.ship.thrustDown();
						break;					
					// left
					case 37:
						if(!this.ship.isRunning)
							this.ship.thrustLeft();						
						break;
					// right				
					case 39:
						if(!this.ship.isRunning)	
							this.ship.thrustRight();
						break;			
					// restart ('r')
					case 82:				
						if(_root.startup == true && (!this.gameStarted || this.gameOver))
						{
							this.mc.instruments_mc._visible = true;
							
							// Show current level interstitial
							this.level();
						}
						break;
					// pause 'p'
					case 80:					
						if(!this.interstitialShown && this.gameStarted)
						{
							this.paused = !this.paused;
							
							if(this.paused)
								this.mc.bg_mc.interstitial_mc.gotoAndStop("_paused")
							else
								this.mc.bg_mc.interstitial_mc.gotoAndStop("_off");
						}
						break;
					// increment level (debug) '+'
					case 107:
						if(this.debugMode)
						{
							this.mc.bg_mc.interstitial_mc.gotoAndStop("_off");
							if(this.gameLevel + 1 <= this.maxLevels)
								this.gameLevel += 1;
							else
								this.gameLevel = 1;
								
							this.restart();
						}
						break;
					// decrement level (debug) '-'
					case 109:
						if(this.debugMode)
						{
							if(this.gameLevel > 0)
							{
								this.mc.bg_mc.interstitial_mc.gotoAndStop("_off");
								this.gameLevel -= 1;
								this.restart();
							}
						}
						break;
				}
			}			
		}
	}
	
	// Utility functions
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// Generates random number between two ranges and strips off the decimal point 04/26/07
	public static function randRangeFloor(min:Number, max:Number) {
		var randomNum:Number = Math.floor(Math.random() * (max - min + 1)) + min;
		return randomNum;
	}	
	
	// Format a number into specified number of decimal places 04/27/07
	public static function formatDecimals (num, digits):Number {
		//if no decimal places needed, we're done
		if (digits <= 0) 
			return Math.round(num); 

		//round the number to specified decimal places
		//e.g. 12.3456 to 3 digits (12.346) -> mult. by 1000, round, div. by 1000
		var tenToPower = Math.pow(10, digits);
		var cropped = String(Math.round(num * tenToPower) / tenToPower);

		//add decimal point if missing
		if (cropped.indexOf(".") == -1) {
			cropped += ".0";  //e.g. 5 -> 5.0 (at least one zero is needed)
		}

		//finally, force correct number of zeroes; add some if necessary
		var halves = cropped.split("."); //grab numbers to the right of the decimal
		//compare digits in right half of string to digits wanted
		var zerosNeeded = digits - halves[1].length; //number of zeros to add
		for (var i=1; i <= zerosNeeded; i++) {
			cropped += "0";
		}
		
		return(cropped);
		
	} //Robert Penner May 2001 - source@robertpenner.com	
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
}