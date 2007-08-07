class Ship
{
	var parent_mc:MovieClip;
	var mc:MovieClip;
	var body_mc:MovieClip;

	var fuelMax:Number = 100;
	var fuel:Number;

	var x:Number = 0.00;
	var y:Number = 0.00;
	var yMax:Number;
	
	var startX:Number;
	var startY:Number;

	var ax:Number = 0;
	var ay:Number = 0;
	var axMax:Number = 0.5;
	var ayMax:Number = -0.7;
	
	var vx:Number = 0.00;
	var vy:Number = 0.00;
	var vxMax:Number = 5;
	var vxMin:Number = -5;
	var vyMax:Number = -5;
	
	var isVisible:Boolean = false;
	var isRunning:Boolean = false;
	var engineOn:Boolean = false;
	var leftEngineOn:Boolean = false;
	var rightEngineOn:Boolean = false;
	var enginesOn:Boolean = false;
	
	function Ship(mc:MovieClip)
	{		
		this.parent_mc = mc;
		this.yMax = this.parent_mc.bg_mc.ground_mc._y;

		this.mc = this.parent_mc.attachMovie("ship_mc", "ship", this.parent_mc.getNextHighestDepth(), {_x:this.parent_mc._width/2,_y:this.yMax/2});
		this.body_mc = this.mc.body_mc;
		
		initShip();	
	}		

	private function initShip()
	{
		// Set fuel
		this.fuel = this.fuelMax;	

		// Scale down ship
		this.mc._xscale = 25;
		this.mc._yscale = 25;
		
		// Reset ship parameters
		resetShip();
	}
	
	public function resetShip()
	{
		this.mc.gotoAndStop("_alive");
		
		this.fuel = this.fuelMax;
		
		// Set ship position info
		this.ax = 0;
		this.ay = 0;
		this.vx = 0;
		this.vy = 0;
		this.x = this.parent_mc._width / 2;
		this.y = this.yMax / 2 - 75;
		
		this.startX = this.x;
		this.startY = this.y;
		
		// Set ship object states
		this.isVisible = true;
		this.isRunning = false;
		this.engineOn = false;
		this.leftEngineOn = false;
		this.rightEngineOn = false;
		
		// Set ship movieclip states
		this.mc._visible = this.isVisible;
		this.mc._x = x;
		this.mc._y = y;
		this.mc.engine_mc.gotoAndStop("_off");
	}
	
	public function move()
	{
		// Set engine animations
		/////////////////////////
		if(Lunar.formatDecimals(this.ay,2) < 0.00)
			this.toggleEngine(true);
		else if(Lunar.formatDecimals(this.ay,2) == 0.00)		
			this.toggleEngine(false);
			
		if(Lunar.formatDecimals(this.ax,2) < 0.00)
			this.toggleRightEngine(true)
		else
			this.toggleRightEngine(false);
			
		if(Lunar.formatDecimals(this.ax,2) > 0.00)
			this.toggleLeftEngine(true);
		else			
			this.toggleLeftEngine(false);			

		// For engine sounds
		if(this.engineOn || this.leftEngineOn || this.rightEngineOn)
			this.enginesOn = true;
		else
			this.enginesOn = false;
		/////////////////////////
		
		// Update velocity based on acceleration
		if(this.vx + this.ax < this.vxMax && this.vx + this.ax > -this.vxMax)
			this.vx += this.ax;
		
		// No downward acceleration
		if(this.vy + this.ay > this.vyMax)
			this.vy += this.ay;

		// Update displacement based on velocity
		this.x += this.vx;
		this.y += this.vy;
					
		// Left/right screen wrap
		if(this.x > Stage.width)
			this.x = 0;
		else if(this.x < 0)
			this.x = Stage.width;
		
		// Stop ship from flying off the screen on top
		if(this.y <= 0)
			this.y = 0;
		
		// Finally, set x/y coord of ship movieclip
		this.mc._x = this.x
		this.mc._y = this.y;		
		
		// Update fuel
		this.fuel -= Math.abs(this.ax);
		this.fuel -= Math.abs(this.ay);
		
		if(this.fuel <= 0)
		{
			this.fuel = 0;
			this.ax = 0;
			this.ay = 0;
		}
	}

	public function shutDown(death:Boolean)
	{
		/*
		this.ax = 0;
		this.ay = 0;
		this.vx = 0;
		this.vy = 0;
		*/
		this.isRunning = false;
		this.toggleEngine(false);
		
		if(death)
			this.mc.gotoAndPlay("_death");
	}
	
	public function thrustRight()
	{
		if(this.fuel > 0)
		{
			if(this.ax < this.axMax)
				this.ax += 0.1;
			else
				this.ax = this.axMax;
		}
	}
	
	public function thrustLeft()
	{
		if(this.fuel > 0)
		{
			if(this.ax > -this.axMax)
				this.ax -= 0.1;
			else
				this.ax = -this.axMax;
		}
	}
	
	// Bug with Flash keyboard events 08/05/07
	// If up is held down and then left/right is touched, 
	// and then up is released, up release is never detected.
	//
	// For now, up will only add thrust like left/right does.
	// Cannot hold down up key.
	public function thrustUp()
	{
		if(this.fuel > 0)
		{
			if(Lunar.formatDecimals(this.ay - 0.1,2) > this.ayMax)
				this.ay -= 0.1;
			else
				this.ay = this.ayMax;
		}
	}
	
	public function thrustDown()
	{
		if(this.fuel > 0)
		{
			if(Lunar.formatDecimals(this.ay + 0.1,2) < 0)
				this.ay += 0.1;
			else
				this.ay = 0;
		}
	}
	
	public function toggleEngine(override:Boolean)
	{
		if(override != undefined)
		{
			if(override == true && !this.engineOn)
			{
				trace("## engines on");
				this.engineOn = override;
				this.mc.engine_mc.gotoAndPlay("_on");
			}
			else if(override == false && this.engineOn)
			{
				trace("## engines off");
				this.engineOn = override;
				this.mc.engine_mc.gotoAndStop("_off");
			}
		}
		else
		{
			this.engineOn = !this.engineOn;
			
			if(this.engineOn)
				this.mc.engine_mc.gotoAndPlay("_on");
			else
				this.mc.engine_mc.gotoAndStop("_off");				
		}					
	}
	
	public function toggleLeftEngine(override:Boolean)
	{
		if(override != undefined)
		{
			if(override == true && !this.leftEngineOn)
			{
				trace("## left engines on");
				this.leftEngineOn = override;
				this.mc.left_engine_mc.gotoAndPlay("_on");
			}
			else if(override == false && this.leftEngineOn)
			{
				trace("## left engines off");
				this.leftEngineOn = override;
				this.mc.left_engine_mc.gotoAndStop("_off");
			}
		}
		else
		{
			this.leftEngineOn = !this.leftEngineOn;
			
			if(this.leftEngineOn)
				this.mc.left_engine_mc.gotoAndPlay("_on");
			else
				this.mc.left_engine_mc.gotoAndStop("_off");				
		}					
	}
	
	public function toggleRightEngine(override:Boolean)
	{
		if(override != undefined)
		{
			if(override == true && !this.rightEngineOn)
			{
				trace("## right engines on");
				this.rightEngineOn = override;
				this.mc.right_engine_mc.gotoAndPlay("_on");
			}
			else if(override == false && this.rightEngineOn)
			{
				trace("## right engines off");
				this.rightEngineOn = override;
				this.mc.right_engine_mc.gotoAndStop("_off");
			}
		}
		else
		{
			this.rightEngineOn = !this.rightEngineOn;
			
			if(this.rightEngineOn)
				this.mc.right_engine_mc.gotoAndPlay("_on");
			else
				this.mc.right_engine_mc.gotoAndStop("_off");				
		}					
	}	
}