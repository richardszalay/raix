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
		
		[Bindable]
		public var showCode : Boolean = true;
	}
}