package rx.impl
{
	import rx.ICancelable;

	public class CompositeSubscription implements ICancelable
	{
		private var _subscriptions : Array;
		
		public function CompositeSubscription(values : Array)
		{
			_subscriptions = new Array().concat(values);
		}
		
		public function add(subscription : ICancelable) : void
		{
			_subscriptions.push(subscription);
		}
		
		public function remove(subscription : ICancelable) : void
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

		public function cancel():void
		{
			while(_subscriptions.length > 0)
			{
				_subscriptions.shift().cancel();
			}
		}
		
		public function get subscriptions() : Array
		{
			return new Array().concat(_subscriptions);
		}
	}
}