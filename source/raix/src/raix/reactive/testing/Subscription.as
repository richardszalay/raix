package raix.reactive.testing
{
	public class Subscription
	{
		public var subscribe : Number;
		public var unsubscribe : Number;
		
		public function Subscription(subscribe : Number, unsubscribe : Number = int.MAX_VALUE)
		{
			this.subscribe = subscribe;
			this.unsubscribe = unsubscribe;
		}
	}
}