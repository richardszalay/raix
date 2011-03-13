package samples
{
	import mx.containers.Canvas;
	
	public class AbsSample extends Canvas
	{
		public function AbsSample()
		{
		}
		
		public function toggleCode() : void
		{
			showCode = !showCode;
		}
		
		public function setup():void { }
		public function teardown():void {}
		
		public function beginSetup() : void
		{
			running = true;
			
			setup();
		}
		
		public function beginTeardown() : void
		{
			running = false;
			
			teardown();
		}
		
		[Bindable]
		public var running : Boolean = false;
		
		[Bindable]
		public var showCode : Boolean = true;
	}
}