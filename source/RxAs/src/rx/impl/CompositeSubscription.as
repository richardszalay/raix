package rx.impl
{
	import rx.ISubscription;

	public class CompositeSubscription implements ISubscription
	{
		private var _subscriptions : Array;
		
		public function CompositeSubscription(values : Array)
		{
			_subscriptions = new Array().concat(values);
		}
		
		public function add(subscription : ISubscription) : void
		{
			_subscriptions.push(subscription);
		}
		
		public function remove(subscription : ISubscription) : void
		{
			for (var i:int=0; i<_subscriptions.length; i++)
			{
				if (_subscriptions[i] == subscription)
				{
					_subscriptions.splice(i, 1);
					break;
				}
			}
		}
		
		public function get count() : uint
		{
			return _subscriptions.length;
		}

		public function unsubscribe():void
		{
			while(_subscriptions.length > 0)
			{
				_subscriptions.shift().unsubscribe();
			}
		}
		
		public function get subscriptions() : Array
		{
			return new Array().concat(_subscriptions);
		}
	}
}